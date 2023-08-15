/*
STORAGE LAYOUT:

owner: slot 0
uri: slot 1
mapping(uint256 id => mapping(address account => uint256)) balances:
  - id => account => balance
mapping(address owner => mapping(address operator => bool)) isApprovedForAll: 
  - owner => operator => bool
*/


object "ERC1155" {
  // constructor
  // this "code" node is the single executable code of the object. 
  code {
    // store caller as owner in the owner storage slot
    sstore(0, caller())

    // deploy the contract
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }

  object "Runtime" {
    // Return the calldata
    code {
      /* --------- DISPATCHER --------- */
      // in most programming languages, it'll evaluate all the case statements, even if one before it is true
      // in yul, it will stop once it finds the first case statemnet that matches
      switch selector()
      // mint(address,uint256,uint256)
      case 0x156e29f6 {
        // decode calldata as value types
        // require(to != address(0))
        // if to address is a smart contract, require that it implements onERC1155Received
        let to := decodeAsAddress(0)
        let id := decodeAsUint(1)
        let value := decodeAsUint(2)

        _mint(to, id, value)
      }

      // mintBatch(address,uint256[],uint256[],bytes)
      case 0x1f7fdffa {

      }


      // safeTransferFrom(address,address,uint256,uint256,bytes)
      case 0xf242432a {

      }

      // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
      case 0x2eb2c2d6 {

      }

      // balanceOf(address,uint256)
      case 0x00fdd58e {

      }

      // balanceOfBatch(address[],uint256[])
      case 0x4e1273f4 {

      }

      // setApprovalForAll(address,bool)
      case 0xa22cb465 {

      }

      // isApprovedForAll(address,address)
      case 0xe985e9c5 {

      }

      // burn(address,uint256,uint256)
      case 0xf5298aca {

      }

      // burnBatch(address,uint256[],uint256[])
      case 0x6b20c454 {
        
      }

      // owner

      default {
        // just revert if no function selector matches
        revert(0, 0)
      }


      /* --------- CALLDATA DECODING --------- */
      /// @dev decode function selector
      function selector() -> s {
        // load calldata from offset 0 and divide to get only first 4 bytes
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

      /// @dev proper checks to ensure it is a valid adddress
      function decodeAsAddress(offset) -> v {
        // decode the calldata at the given offset
        v := decodeAsUint(offset)
        // checks whether it is the zero address and reverts if so
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
        }
      }

      /// @dev decode calldata at given offset
      function decodeAsUint(offset) -> v {
          // 4 bytes to skip the function selector
          let pos := add(4, mul(offset, 0x20))
          // check if there is 32 bytes of calldata left to read
          if lt(calldatasize(), add(pos, 0x20)) {
              revert(0, 0)
          }
          // return the value at the specified position in calldata
          v := calldataload(pos)
      }

      /* --------- FUNCTIONS --------- */

      function owner() -> o {
        o := sload(ownerSlot())
      }

      /// @dev used to return the value that you pass into the function
      function returnUint(v) {
        // store value into memory first and then return it
        mstore(0, v)
        return(0, 0x20)
      }

      /// @dev used to return the value 1, which represents true
      function returnTrue() {
        returnUint(1)
      }

      function _mint(account, id, amount) {
        // balances[to][id] += value
          // get offset of where balance mapping is stored
          // get offset of where balances[to][id] is stored
        // emit mint event
      }

      /* --------- STORAGE ACCESS --------- */
      function ownerSlot() -> p {
        p := 0
      }
      

      /* --------- EVENTS --------- */
    }
  }
}