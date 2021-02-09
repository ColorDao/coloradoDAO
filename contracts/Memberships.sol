// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Membership is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string public tokenURI;
  uint256 public proposalCount;

  struct Proposal {
    uint256 id;
    address proposer;
    string did;
    bool denied;
    bool accepted;
  }

  mapping(uint256 => Proposal) public proposals;

  mapping(address => uint256) public latestProposalIds;

  constructor(string memory _tokenURI, address _governor)
    ERC721("Membership", "COL")
  {
    tokenURI = _tokenURI;
    transferOwnership(_governor);
  }

  function requestMembership(string memory _did) public {
    uint256 latestProposalId = latestProposalIds[msg.sender];
    require(latestProposalId != 0, "One live proposal per proposer");
    proposalCount++;
    Proposal memory newProposal =
      Proposal({
        id: proposalCount,
        proposer: msg.sender,
        did: _did,
        denied: false,
        accepted: false
      });
    proposals[newProposal.id] = newProposal;
  }

  function denyMembership(uint256 proposalId) public onlyOwner {
    Proposal storage proposal = proposals[proposalId];
    proposal.denied = true;
  }

  function grantMembership(uint256 proposalId)
    public
    onlyOwner
    returns (uint256)
  {
    _tokenIds.increment();
    Proposal storage proposal = proposals[proposalId];
    proposal.accepted = true;
    uint256 newMembershipId = _tokenIds.current();
    _mint(proposal.proposer, newMembershipId);
    _setTokenURI(newMembershipId, tokenURI);

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
