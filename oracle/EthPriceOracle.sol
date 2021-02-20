// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../caller/EthPriceOracleInterface.sol";
import "./CallerContracInterface.sol";


contract EthPriceOracle is Ownable {
  uint private randNonce = 0;
  uint private modulus = 1000;
  mapping(uint256=>bool) pendingRequests;
  event GetLatestEthPriceEvent(address callerAddress, uint id);
  event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
  function getLatestEthPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestEthPriceEvent(msg.sender, id);
    return id;  
  }
  function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public onlyOwner {
    require(pendingRequests[_id], "This request is not in my pending list.");
    delete pendingRequests[_id];
    CallerContracInterface callerContractInstance;
    callerContractInstance = CallerContracInterface(_callerAddress);
    callerContractInstance.callback(_ethPrice, _id);
    emit SetLatestEthPriceEvent(_ethPrice, _callerAddress);

  }
}
