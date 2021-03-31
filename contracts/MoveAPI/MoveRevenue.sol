pragma solidity ^0.5.0;
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.5/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.5/vendor/Ownable.sol";

// v2.1
contract MoveRevenue is ChainlinkClient, Ownable {
    uint256 private constant ORACLE_PAYMENT = 1 * LINK;
    string private apikey;
    uint256 public currentMoveRevenue;

    event RequestMoveRevenue(
        bytes32 indexed requestId,
        uint256 indexed movieRevenue
    );
    event APIKeyTransferred(
        string indexed previousAPIKey,
        string indexed apiKey
    );

    constructor(
        string memory _apikey,
        address _chainLinkToken,
        address _orcale
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

    // withdraw
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    // get/set
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getChainlinkOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function transferChainlinkAPIKey(string memory newAPIKey) public onlyOwner {
        _transferChainlinkAPIKey(newAPIKey);
    }

    function _transferChainlinkAPIKey(string memory newAPIKey) internal {
        require(bytes(newAPIKey).length != 0, "APIKey: api key is empty.");
        emit APIKeyTransferred(apikey, newAPIKey);
        apikey = newAPIKey;
    }

    // Tool
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
        return string(abi.encodePacked(url, _moveId, "?api_key=", apikey));
    }
}
