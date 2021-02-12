// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface COLOInterface {
  function mint(address account, uint256 rawAmount) external;
}

contract Memberships is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string public tokenURI;
  uint256 public proposalCount;
  COLOInterface public COLO;

  uint256 reward = 10 ether;

  struct Proposal {
    uint256 id;
    address proposer;
    string did;
    bool accepted;
    bool revision;
  }

  mapping(uint256 => Proposal) public proposals;

  mapping(address => uint256) public latestProposalIds;

  constructor(
    string memory _tokenURI,
    address _governor,
    address _COLO
  ) ERC721("Membership", "COL") {
    tokenURI = _tokenURI;
    COLO = COLOInterface(_COLO);
    transferOwnership(_governor);
  }

  function requestMembership(string memory _did) public {
    uint256 latestProposalId = latestProposalIds[msg.sender];
    require(latestProposalId == 0, "One live proposal per proposer");
    proposalCount++;
    Proposal memory newProposal =
      Proposal({
        id: proposalCount,
        proposer: msg.sender,
        did: _did,
        accepted: false,
        revision: false
      });
    proposals[newProposal.id] = newProposal;
  }

  function denyMembership(uint256 proposalId) public onlyOwner {
    Proposal storage proposal = proposals[proposalId];
    require(balanceOf(proposal.proposer) == 0, "Can't deny an approved"); // Deny could work if we burn the membership
    proposal.revision = true;
    proposal.accepted = false;
  }

  function grantMembership(uint256 proposalId)
    public
    onlyOwner
    returns (uint256)
  {
    _tokenIds.increment();
    Proposal storage proposal = proposals[proposalId];
    require(balanceOf(proposal.proposer) == 0, "Can't mint two tokens");
    proposal.accepted = true;
    proposal.revision = true;
    uint256 newMembershipId = _tokenIds.current();
    _mint(proposal.proposer, newMembershipId);
    _setTokenURI(newMembershipId, tokenURI);
    COLO.mint(proposal.proposer, reward);
    return newMembershipId;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    require(from == address(0), "Token can't be transfer");
  }
}
