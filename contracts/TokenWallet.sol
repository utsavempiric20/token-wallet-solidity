// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function mint(address account, uint256 value) external;
}

contract TokenWallet {
    IERC20 iERC20;
    struct User {
        address userAddress;
        string userName;
        address referalByWhom;
        uint256 tokenAmount;
    }

    string tokenName;
    string tokenSymbol;
    uint256 InitialTokens;
    uint256 FirstBonusTokens;
    uint256 SecondBounsTokens;
    uint256 ThirdBonusTokens;
    uint256[3] bounsTokensOfUser;

    mapping(address => User) users;
    mapping(string => bool) isUserExist;
    mapping(address => string) userReferalCode;
    mapping(string => address) getAddressFromCode;
    mapping(address => address[]) usersAllReferals;

    constructor(address _iERC20) {
        iERC20 = IERC20(_iERC20);
        InitialTokens = 100 * 10 ** decimals();
        FirstBonusTokens = 20 * 10 ** decimals();
        SecondBounsTokens = 10 * 10 ** decimals();
        ThirdBonusTokens = 5 * 10 ** decimals();
        bounsTokensOfUser = [
            FirstBonusTokens,
            SecondBounsTokens,
            ThirdBonusTokens
        ];
    }

    function register(
        string memory _username,
        string memory _referalCode
    ) public {
        require(!isUserExist[_username], "Username already Exist.");
        isUserExist[_username] = true;
        if (
            keccak256(abi.encodePacked(_referalCode)) !=
            keccak256(abi.encodePacked("NA"))
        ) {
            // A -----> B -----> c -----> D
            // <--20--  <--20--  <--20--
            // <-------10--------
            //          <--------10--------
            // <------------5--------------

            iERC20.mint(msg.sender, InitialTokens + FirstBonusTokens);

            address refererUser = getAddressFromCode[_referalCode];
            for (uint256 i = 0; i < bounsTokensOfUser.length; i++) {
                if (refererUser == address(0)) {
                    break;
                }
                iERC20.mint(refererUser, bounsTokensOfUser[i]);
                User storage user = users[refererUser];
                user.tokenAmount = iERC20.balanceOf(refererUser);
                refererUser = user.referalByWhom;
            }

            // address refererUser = getAddressFromCode[_referalCode];
            // for (uint256 i = 0; i < 3; i++) {
            //     console.log("before refererUser--> ", refererUser);
            //     console.log("0 address(0)--> ", address(0));
            //     if (refererUser == address(0)) {
            //         break;
            //     }
            //     if (i == 0) {
            //         console.log("0");
            //         iERC20.mint(refererUser, FirstBonusTokens);
            //     } else if (i == 1) {
            //         console.log("1");
            //         iERC20.mint(refererUser, SecondBounsTokens);
            //     } else if (i == 2) {
            //         console.log("2");
            //         iERC20.mint(refererUser, ThirdBonusTokens);
            //     }
            //     refererUser = users[refererUser].referalByWhom;
            //     console.log("after refererUser--> ", refererUser);
            // }

            // address firstRefererUser = getAddressFromCode[_referalCode];
            // iERC20.mint(firstRefererUser, FirstBonusTokens); // 20  B    C

            // User storage firstUser = users[firstRefererUser];
            // firstUser.tokenAmount = iERC20.balanceOf(firstRefererUser);
            // address secondRefererUser = firstUser.referalByWhom;

            // if (secondRefererUser != address(0)) {
            //     iERC20.mint(secondRefererUser, SecondBounsTokens); // 10 A     B

            //     User storage secondUser = users[secondRefererUser];
            //     secondUser.tokenAmount = iERC20.balanceOf(secondRefererUser);
            //     address thirdRefererUser = secondUser.referalByWhom;

            //     if (thirdRefererUser != address(0)) {
            //         iERC20.mint(thirdRefererUser, ThirdBonusTokens); // 5  A
            //         User storage thirdUser = users[thirdRefererUser];
            //         thirdUser.tokenAmount = iERC20.balanceOf(thirdRefererUser);
            //     }
            // }

            registerRefererUser(_username, _referalCode);
        } else {
            iERC20.mint(msg.sender, InitialTokens);
            registerRefererUser(_username, _referalCode);
        }
    }

    function registerRefererUser(
        string memory _username,
        string memory _referalCode
    ) internal {
        bytes32 hashOfReferalCode = keccak256(
            abi.encodePacked(block.timestamp, _username)
        );
        string memory referalCode = substring(
            bytes32ToString(hashOfReferalCode),
            0,
            6
        );
        address referalByWhom = getAddressFromCode[_referalCode];
        uint256 balanceOfUser = iERC20.balanceOf(msg.sender);

        User memory user = User({
            userAddress: msg.sender,
            userName: _username,
            referalByWhom: referalByWhom,
            tokenAmount: balanceOfUser
        });

        users[msg.sender] = user;
        userReferalCode[msg.sender] = referalCode;
        getAddressFromCode[referalCode] = msg.sender;
        usersAllReferals[user.referalByWhom].push(msg.sender);
    }

    function bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytesArray[i * 2] = _toHexChar(uint8(_bytes32[i] >> 4));
            bytesArray[i * 2 + 1] = _toHexChar(uint8(_bytes32[i] & 0x0f));
        }
        return string(bytesArray);
    }

    function _toHexChar(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(_value + 0x30);
        } else {
            return bytes1(_value + 0x57);
        }
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getUser()
        public
        view
        returns (
            address userAddress,
            string memory userName,
            address referalByWhom,
            uint256 tokenAmount
        )
    {
        User memory user = users[msg.sender];
        return (
            user.userAddress,
            user.userName,
            user.referalByWhom,
            user.tokenAmount
        );
    }

    function getUserReferalCode() public view returns (string memory) {
        return userReferalCode[msg.sender];
    }

    function getUserAddressFromReferalCode(
        string memory referalCode
    ) public view returns (address) {
        return getAddressFromCode[referalCode];
    }

    function getAllUsersReferals() public view returns (address[] memory) {
        return usersAllReferals[msg.sender];
    }

    function getTokenName() public view returns (string memory) {
        return iERC20.name();
    }

    function getTokenSymbol() public view returns (string memory) {
        return iERC20.symbol();
    }

    function getBalance() public view returns (uint256) {
        return iERC20.balanceOf(msg.sender);
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }
}
