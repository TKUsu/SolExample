pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/vendor/Ownable.sol";

// MyContract inherits the ChainlinkClient contract to gain the
// functionality of creating Chainlink requests
contract ChainlinkExample is ChainlinkClient {
    // Helper constant for testnets: 1 request = 1 LINK
    uint256 private constant ORACLE_PAYMENT = 1 * LINK;

    // Stores the answer from the Chainlink oracle
    uint256 public currentPrice;
    address public owner;

    constructor(address _chainlink, address _oracle) public {
        // Set the address for the LINK token for the network
        setChainlinkToken(_chainlink);
        // Set the address of the oracle to create requests to
        setChainlinkOracle(_oracle);
        owner = msg.sender;
    }

    function requestEthereumPrice(address _oracle, string memory _jobId)
        public
        onlyOwner
    {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                stringToBytes32(_jobId),
                address(this),
                this.fulfill.selector
            );
        req.add(
            "get",
            "https://min-api.cryptocompare.com/data/price?fsym=TT&tsyms=USD"
        );
        req.add("path", "USD");
        req.addInt("times", 1000000);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    // fulfill receives a uint256 data type
    function fulfill(bytes32 _requestId, uint256 _price)
        public
        // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
        recordChainlinkFulfillment(_requestId)
    {
        currentPrice = _price;
    }

    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
