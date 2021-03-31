pragma solidity ^0.5.0;
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.5/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.5/vendor/Ownable.sol";

contract MoveRevenue is ChainlinkClient, Ownable {
    uint256 private constant ORACLE_PAYMENT = 1 * LINK;
    string private apikey;
    uint256 public currentMoveRevenue;

    event RequestMoveRevenue(
        bytes32 indexed requestId,
        uint256 indexed movieRevenue
    );
    event RequestEthereumPriceFulfilled(
        bytes32 indexed requestId,
        uint256 indexed price
    );

    constructor(
        string memory _apikey,
        address _orcale,
        address _chainLinkToken
    ) public Ownable() {
        apikey = _apikey;
        setChainlinkToken(_chainLinkToken);
        setChainlinkOracle(_orcale);
    }

    function requestMoveRevenue(string memory _jobId, string memory _moveId)
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                stringToBytes32(_jobId),
                address(this),
                this.fulfillMoveRevenue.selector
            );
        string memory url = getMoveURL(_moveId);
        req.add("get", url);
        req.add("path", "revenue");
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    function fulfillMoveRevenue(bytes32 _requestId, uint256 _movieRevenue)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit RequestMoveRevenue(_requestId, _movieRevenue);
        currentMoveRevenue = _movieRevenue;
    }

    // Chainlink Example
    uint256 public currentPrice;

    // Creates a Chainlink request with the uint256 multiplier job and returns the requestId
    function requestEthereumPrice(string memory _jobId, string memory _currency)
        public
        returns (bytes32 requestId)
    {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req =
            buildChainlinkRequest(
                stringToBytes32(_jobId),
                address(this),
                this.fulfillEthereumPrice.selector
            );
        // Adds a URL with the key "get" to the request parameters
        req.add(
            "get",
            "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,JPY"
        );
        // Uses input param (dot-delimited string) as the "path" in the request parameters
        req.add("path", _currency);
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", 100);
        // Sends the request with 1 LINK to the oracle contract
        requestId = sendChainlinkRequest(req, 1 * LINK);
    }

    // fulfillEthereumPrice receives a uint256 data type
    function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
        public
        // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
        recordChainlinkFulfillment(_requestId)
    {
        currentPrice = _price;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getChainlinkOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
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

    function getMoveURL(string memory _moveId)
        public
        view
        returns (string memory)
    {
        string memory url = "https://api.themoviedb.org/3/movie/";
        return
            string(
                abi.encodePacked(
                    url,
                    _moveId,
                    "?api_key=",
                    apikey,
                    "&language=zh-TW"
                )
            );
    }
}
