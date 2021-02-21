// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../caller/contracts/EthPriceOracleInterface.sol";
import "./CallerContracInterface.sol";


contract EthPriceOracle is ERC20,  AccessControl {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
  uint private THRESHOLD = 0;
  using SafeMath for uint256;

  struct Response {
      address oracleAddress;
      address callerAddress;
      uint256 ethPrice;
    }
  uint private randNonce = 0;
  uint private modulus = 1000;
  uint private numOracles = 0;

  mapping(uint256=>bool) pendingRequests;
  mapping (uint256=>Response[]) public requestIdToResponse;

  event GetLatestEthPriceEvent(address callerAddress, uint id);
  event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
  event AddOracleEvent(address oracleAddress);
  event RemoveOracleEvent(address oracleAddress);
  event SetThresholdEvent (uint threshold);


    constructor(address _owner) public ERC20("MyToken", "TKN") {
        _setupRole(OWNER_ROLE, _owner);
    }
    function addOracle (address _oracle) public {
      require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
      require(!hasRole(ORACLE_ROLE, _oracle), "Already an oracle!");
      _setupRole(ORACLE_ROLE, _oracle);
      numOracles++;
      emit AddOracleEvent(_oracle);    
    }
    function removeOracle (address _oracle) public {
      require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
      require(hasRole(ORACLE_ROLE, _oracle), "Not an oracle!");
      require (numOracles > 1, "Do not remove the last oracle!");
      numOracles--;
      emit RemoveOracleEvent(_oracle);
  }

  function getLatestEthPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestEthPriceEvent(msg.sender, id);
    return id;  
  }
  
  function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public {
    require(pendingRequests[_id], "This request is not in my pending list.");
    require(hasRole(ORACLE_ROLE, msg.sender), "Not an oracle!");
    Response memory resp;
    resp = Response(msg.sender, _callerAddress, _ethPrice);
    requestIdToResponse[_id].push(resp);
    delete pendingRequests[_id];
    uint numResponses = requestIdToResponse[_id].length;
    if (numResponses == THRESHOLD) {
      uint computedEthPrice = 0;
      for (uint f=0; f < requestIdToResponse[_id].length; f++) {
        computedEthPrice =   computedEthPrice.add(requestIdToResponse[_id][f].ethPrice);
      }
      computedEthPrice = computedEthPrice.div(numResponses);
      delete requestIdToResponse[_id];

      CallerContracInterface callerContractInstance;
      callerContractInstance = CallerContracInterface(_callerAddress);
      callerContractInstance.callback(computedEthPrice, _id);
      emit SetLatestEthPriceEvent(computedEthPrice, _callerAddress);
    }
  }

  function setThreshold (uint _threshold) public {
    require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
    THRESHOLD = _threshold;
    emit SetThresholdEvent(THRESHOLD);
  }
}
