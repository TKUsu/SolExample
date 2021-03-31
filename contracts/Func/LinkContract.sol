pragma solidity 0.4.24;

contract LinkContract {

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // 返還所有 Link 回部署者。
    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}