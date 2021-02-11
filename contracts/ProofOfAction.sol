// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface COLOInterface {
  function mint(address account, uint256 rawAmount) external;
}

interface Membership {
  function balanceOf(address account) external view returns (uint256);
}

contract ProofOfWork is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter public proofCounts;
  Counters.Counter public requestsCount;

  struct Proof {
    uint256 id;
    address proposer;
    string did;
    uint256 requestId;
    bool accepted;
    bool revision;
  }

  struct Request {
    uint256 id;
    string requirements;
    bool active;
    uint256 reward;
  }

  COLOInterface public COLO;
  Membership public membership;

  mapping(uint256 => Proof) public proofs;
  mapping(uint256 => Request) public requests;

  constructor(
    address _COLO,
    address _membership,
    address _governor
  ) {
    COLO = COLOInterface(_COLO);
    membership = Membership(_membership);
    transferOwnership(_governor);
  }

  function submitProof(uint256 _requestId, string memory _proofDid) public {
    require(membership.balanceOf(msg.sender) > 0, "Only members can submit");
    Request memory request = requests[_requestId];
    require(request.active, "Request must be active");
    proofCounts.increment();
    Proof memory newProof =
      Proof({
        id: proofCounts.current(),
        proposer: msg.sender,
        did: _proofDid,
        requestId: _requestId,
        accepted: false,
        revision: false
      });
    proofs[newProof.id] = newProof;
  }

  function denyProof(uint256 proofId) public onlyOwner {
    Proof storage proof = proofs[proofId];
    proof.accepted = false;
    proof.revision = true;
  }

  function grantProof(uint256 proofId) public onlyOwner {
    Proof storage proof = proofs[proofId];
    Request memory request = requests[proof.requestId];
    require(proof.revision == false, "Proof already revised");
    proof.accepted = true;
    proof.revision = true;
    COLO.mint(proof.proposer, request.reward);
  }

  function createRequest(string memory _requirements, uint256 _reward)
    public
    onlyOwner
  {
    requestsCount.increment();
    Request memory newRequest =
      Request({
        id: requestsCount.current(),
        requirements: _requirements,
        active: true,
        reward: _reward
      });
    requests[newRequest.id] = newRequest;
  }

  function closeRequest(uint256 requestId) public onlyOwner {
    Request storage request = requests[requestId];
    require(request.active, "Request must be active");
    request.active = false;
  }
}
