// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Membership is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public tokenURI;

  constructor(string memory _tokenURI, address _governor)
    ERC721("Membership", "COL")
  {
    tokenURI = _tokenURI;
    transferOwnership(_governor);
  }

  function grantMembership(address citizen) public onlyOwner returns (uint256) {
    _tokenIds.increment();

    uint256 newMembershipId = _tokenIds.current();
    _mint(citizen, newMembershipId);
    _setTokenURI(newMembershipId, tokenURI);

    return newMembershipId;
  }
}
