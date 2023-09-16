# ERC1155 Implemented in Yul

## Introduction

This repository implements the ERC1155 token standard in pure yul. The full implementation can be found in `yul/ERC1155.yul`.

For simplicity, the initial URI string has been hardcoded to `https://www.WGMIApe.com` and the deployer of the contract is automatically set as the owner.

## Tests

Test cases can be found in `test/ERC1155.t.sol`. Additionally, the `lib` folder includes a mock `ERC1155Receiver` contract in order
to test for cases where the recipient is a smart contract (i.e. must implement the ERC1155 received hook). The `YulDeployer.sol` contract is a helper that compiles our
Yul contract into bytecode and deploys it. This is used for testing purposes, but can also be further used to deploy a Yul contract on chain.

Run tests:
```
forge test
```

To see the console logs during tests:
```
forge test -vvv
```