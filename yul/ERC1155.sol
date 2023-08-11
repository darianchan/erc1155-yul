/*
STORAGE LAYOUT:
Balance Mapping:
Allowance Mapping:
Slot for URI
Slot for Owner (not sure if I need this)
*/


object "ERC1155" {
  // constructor
  // this "code" node is the single executable code of the object. 
  code {
    // deploy the contract - return the runtime code after running it?
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

      default {
          
      }

      /* --------- FUNCTIONS --------- */
      function selector() -> s {
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

      /* --------- EVENTS --------- */
    }
  }
}