// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error OnlyBuyer();
error OnlySeller();
error OnlyArbiter();
error InvalidState();
error DeadlineNotPassed();
error TransferFailed();

contract P2PEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum State { Created, Funded, Completed, Disputed, Refunded }

    struct Escrow {
        address buyer;
        address seller;
        address arbiter;
        address token; // address(0) for ETH
        uint256 amount;
        uint256 deadline;
        State currentState;
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;

    event EscrowCreated(uint256 indexed id, address buyer, address seller, uint256 amount);
    event EscrowFunded(uint256 indexed id);
    event EscrowReleased(uint256 indexed id);
    event EscrowDisputed(uint256 indexed id);
    event DisputeResolved(uint256 indexed id, address winner);

    function createEscrow(
        address _seller,
        address _arbiter,
        address _token,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint256) {
        uint256 id = escrowCount++;
        escrows[id] = Escrow({
            buyer: msg.sender,
            seller: _seller,
            arbiter: _arbiter,
            token: _token,
            amount: _amount,
            deadline: block.timestamp + _duration,
            currentState: State.Created
        });

        emit EscrowCreated(id, msg.sender, _seller, _amount);
        return id;
    }

    function fundEscrow(uint256 _id) external payable nonReentrant {
        Escrow storage e = escrows[_id];
        if (e.currentState != State.Created) revert InvalidState();
        
        if (e.token == address(0)) {
            require(msg.value == e.amount, "Incorrect ETH amount");
        } else {
            IERC20(e.token).safeTransferFrom(msg.sender, address(this), e.amount);
        }

        e.currentState = State.Funded;
        emit EscrowFunded(_id);
    }

    function releaseFunds(uint256 _id) external nonReentrant {
        Escrow storage e = escrows[_id];
        if (msg.sender != e.buyer) revert OnlyBuyer();
        if (e.currentState != State.Funded) revert InvalidState();

        e.currentState = State.Completed;
        _pay(e.token, e.seller, e.amount);
        
        emit EscrowReleased(_id);
    }

    function initiateDispute(uint256 _id) external {
        Escrow storage e = escrows[_id];
        if (msg.sender != e.buyer && msg.sender != e.seller) revert InvalidState();
        if (e.currentState != State.Funded) revert InvalidState();

        e.currentState = State.Disputed;
        emit EscrowDisputed(_id);
    }

    function resolveDispute(uint256 _id, address _winner) external nonReentrant {
        Escrow storage e = escrows[_id];
        if (msg.sender != e.arbiter) revert OnlyArbiter();
        if (e.currentState != State.Disputed) revert InvalidState();
        if (_winner != e.buyer && _winner != e.seller) revert InvalidState();

        e.currentState = (_winner == e.seller) ? State.Completed : State.Refunded;
        _pay(e.token, _winner, e.amount);

        emit DisputeResolved(_id, _winner);
    }

    function _pay(address _token, address _to, uint256 _amount) internal {
        if (_token == address(0)) {
            (bool success, ) = payable(_to).call{value: _amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}
