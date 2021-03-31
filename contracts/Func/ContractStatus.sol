pragma solidity 0.4.24;

contract ContractStatus {

    function destroy() public payable onlyOwner {
        selfdestruct(owner);
    }
}