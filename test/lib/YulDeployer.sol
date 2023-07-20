// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

contract YulDeployer is Test {
    ///@notice Compiles a Yul contract and returns the address that the contract was deployed to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the Yul contract. For example, the file name for "Example.yul" is "Example"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployContract(string memory fileName) public returns (address) {
        string memory bashCommand = string.concat('cast abi-encode "f(bytes)" $(solc --strict-assembly yul/', string.concat(fileName, ".yul --bin | tail -1)"));

        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;

        bytes memory bytecode = abi.decode(vm.ffi(inputs), (bytes));
        // bytes memory bytecode = hex"600a600d600039600a6000f3fe600035608052366080f3";

        ///@notice deploy the bytecode with the create instruction
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "YulDeployer could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
