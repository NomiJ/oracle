// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

abstract contract CallerContracInterface {
  function callback(uint256 _ethPrice, uint256 id) public virtual;
}
