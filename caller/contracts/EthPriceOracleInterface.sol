// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

abstract contract EthPriceOracleInterface {
  function getLatestEthPrice() public virtual returns (uint256);
}
