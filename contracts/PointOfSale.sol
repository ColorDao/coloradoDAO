// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface COLOInterface {
  function mint(address account, uint256 rawAmount) external;
}

interface ERC20 {
  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool);
}

interface Membership {
  function balanceOf(address account) external view returns (uint256);
}

contract PointOfSale is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter public requestCount;
  string public tokenURI;
  uint256 public proposalCount;
  uint256 public constant DELAY_BETWEEN_BUYS = 30 days;
  uint256 public reward;

  struct Request {
    uint256 id;
    address seller;
    address buyer;
    uint256 amount;
    bool completed;
    address token;
    bool onEth;
  }

  COLOInterface public COLO;
  Membership public membership;

  mapping(uint256 => Request) public requests;
  mapping(address => uint256) public latestRewardDate;
  mapping(address => bool) public vendors;

  constructor(
    address _COLO,
    address _membership,
    address _governor,
    uint256 _reward
  ) {
    COLO = COLOInterface(_COLO);
    membership = Membership(_membership);
    transferOwnership(_governor);
    reward = _reward;
  }

  function setVendorStatus(address _vendor, bool status) public onlyOwner {
    vendors[_vendor] = status;
  }

  function createRequest(
    uint256 _amount,
    address _buyer,
    address _token
  ) public {
    require(vendors[msg.sender], "only vendors can create requests");
    requestCount.increment();
    Request memory newRequest =
      Request({
        id: requestCount.current(),
        seller: msg.sender,
        buyer: _buyer,
        amount: _amount,
        token: _token,
        onEth: false,
        completed: false
      });
    requests[newRequest.id] = newRequest;
  }

  function createRequestETH(uint256 _amount, address _buyer) public {
    require(vendors[msg.sender], "only vendors can create requests");
    requestCount.increment();
    Request memory newRequest =
      Request({
        id: requestCount.current(),
        seller: msg.sender,
        buyer: _buyer,
        amount: _amount,
        token: address(0),
        onEth: true,
        completed: false
      });
    requests[newRequest.id] = newRequest;
  }

  function payRequest(uint256 requestId) public {
    Request storage request = requests[requestId];
    require(!request.completed, "request must be open");
    request.completed = true;
    require(
      ERC20(request.token).transferFrom(
        msg.sender,
        request.seller,
        request.amount
      ),
      "Transfer failed"
    );
    if (
      membership.balanceOf(request.buyer) > 0 &&
      block.timestamp > latestRewardDate[request.buyer]
    ) {
      latestRewardDate[request.buyer] = block.timestamp + DELAY_BETWEEN_BUYS;
      COLO.mint(request.buyer, reward);
    }
  }

  function payRequestETH(uint256 requestId) public payable {
    Request storage request = requests[requestId];
    require(!request.completed, "request must be open");
    require(msg.value == request.amount, "amount not valid");
    request.completed = true;
    payable(request.seller).transfer(msg.value);
    if (
      membership.balanceOf(request.buyer) > 0 &&
      block.timestamp > latestRewardDate[request.buyer]
    ) {
      latestRewardDate[request.buyer] = block.timestamp + DELAY_BETWEEN_BUYS;
      COLO.mint(request.buyer, reward);
    }
  }
}
