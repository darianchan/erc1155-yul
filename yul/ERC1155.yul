/*
STORAGE LAYOUT:

owner: slot 0
mapping(uint256 id => mapping(address account => uint256)) balances: (slot 1)
  - firstHash = keccak256(id, 1)
  - slot = keccak256(account, firstHash)
mapping(address owner => mapping(address operator => bool)) operatorApprovalsSlot: (slot 2)
  - firstHash = keccak256(owner, 2)
  - slot = keccak256(operator, firstHash)
uri: slot 3
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
        let from := decodeAsAddress(0)
        let to := decodeAsAddress(1)
        let id := decodeAsUint(2)
        let value := decodeAsUint(3)
        // check if from == msg.sender or if caller is an approved operator

        // check that the from address has enough balance to make the transfer

        _safeTransferFrom()
      }

      // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
      case 0x2eb2c2d6 {

      }

      // balanceOf(address,uint256)
      case 0x00fdd58e {
        let account := decodeAsAddress(0)
        let id := decodeAsUint(1)
        returnUint(_balanceOf(account, id))
      }

      // balanceOfBatch(address[],uint256[])
      case 0x4e1273f4 {

      }

      // setApprovalForAll(address,bool)
      case 0xa22cb465 {
        let operator := decodeAsAddress(0)
        let isApproved := decodeAsUint(1)

        _setApprovalForAll(caller(), operator, isApproved)
      }

      // isApprovedForAll(address,address)
      case 0xe985e9c5 {
        let tokenOwner := decodeAsAddress(0)
        let operator := decodeAsAddress(1)

        returnUint(_isApprovedForAll(tokenOwner, operator))
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

      function _mint(account, id, amount) {
        let offset := _accountBalanceStorageOffset(account, id)
        let prevBalance := sload(offset)
        sstore(offset, add(prevBalance, amount))
        // minted := returnTrue()
        // emit mint event
      }

      function _mintBatch(account, id, amount) {

      }

      function _balanceOf(account, id) -> amount {
        let offset := _accountBalanceStorageOffset(account, id)
        amount := sload(offset)
      }

      /// @dev sets approval for all
      function _setApprovalForAll(tokenOwner, operator, isApproved) {
        // get offset of the isApprovedForAll mapping
        let offset := _approvalForAllOffset(tokenOwner, operator)
        // set the value to true or false
        sstore(offset, isApproved)
      }

      function _isApprovedForAll(tokenOwner, operator) -> isApproved {
        let offset := _approvalForAllOffset(tokenOwner, operator)
        isApproved := sload(offset)
      }

      function _safeTransferFrom(from, to, id, value, data) {

      }

      /* --------- STORAGE ACCESS --------- */
      function ownerSlot() -> p {
        p := 0
      }

      function balancesSlot() -> p {
        p := 1
      }

      function _operatorApprovalsSlot() -> p {
        p := 2
      }

        function uriSlot() -> p {
        p := 3
      }
      

      /// @dev get the offset for the given account's balance => balances[id][account]
      function _accountBalanceStorageOffset(account, id) -> offset {
        // firstHash = keccak256(id, balancesSlot)
        // slot = keccak256(account, firstHash)
        // store the first hash in memory location 0x60 to be used for second hash
        // store id, balances slot, and account to hash later on
        mstore(0, id)
        mstore(0x20, balancesSlot())
        mstore(0x40, account)
        mstore(0x60, keccak256(0, 0x40))
        offset := keccak256(0x40, 0x80)
      }

      /// @dev get the offset for the given operator's account approval
      function _approvalForAllOffset(tokenOwner, operator) -> offset {
        // firstHash = keccak256(owner, operatorApprovalsSlot) 
        // storage slot = keccak256(operator, firstHash)
        mstore(0, tokenOwner)
        mstore(0x20, _operatorApprovalsSlot())
        mstore(0x40, operator)
        mstore(0x60, keccak256(0, 0x40))
        offset := keccak256(0x40, 0x80)
      }

      /* --------- EVENTS --------- */



      /* --------- HELPERS --------- */
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
    }
  }
}