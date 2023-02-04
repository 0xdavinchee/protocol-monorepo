// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.16;

import { console, Test } from "forge-std/Test.sol";
import {
    IConstantFlowAgreementV1
} from "../../../contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    IInstantDistributionAgreementV1
} from "../../../contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {
    ISuperfluid
} from "../../../contracts/interfaces/superfluid/ISuperfluid.sol";
import {
    IERC20,
    ISuperToken
} from "../../../contracts/interfaces/superfluid/ISuperToken.sol";
import { CFAv1Library } from "../../../contracts/apps/CFAv1Library.sol";
import { IDAv1Library } from "../../../contracts/apps/IDAv1Library.sol";

contract Gas is Test {
    uint256 polygonFork;

    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");

    using CFAv1Library for CFAv1Library.InitData;
    using IDAv1Library for IDAv1Library.InitData;

    CFAv1Library.InitData public cfaV1;
    IDAv1Library.InitData public idaV1;
    ISuperfluid public constant host =
        ISuperfluid(0x3E14dC1b13c488a8d5D310918780c983bD5982E7);
    IERC20 public constant weth =
        IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    ISuperToken public constant ethX =
        ISuperToken(0x27e1e4E6BC79D93032abef01025811B7E4727e85);
    address public constant TEST_ACCOUNT =
        0x0154d25120Ed20A516fE43991702e7463c5A6F6e;
    address public constant ALICE = address(1);
    address public constant BOB = address(2);
    address public constant DEFAULT_FLOW_OPERATOR = address(69);

    // uint256 marketingNFTDeploymentBlock = 34616690;

    function setUp() public {
        vm.startPrank(TEST_ACCOUNT);
        polygonFork = vm.createSelectFork(POLYGON_RPC_URL);
        cfaV1 = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(0x6EeE6060f715257b970700bc2656De21dEdF074C)
        );
        idaV1 = IDAv1Library.InitData(
            host,
            IInstantDistributionAgreementV1(0xB0aABBA4B2783A72C52956CDEF62d438ecA2d7a1)
        );
        // vm.rollFork(marketingNFTDeploymentBlock);

        // these functions are executed in set up so we can get an accurate gas estimate in the
        // test functions

        // approve max amount to upgrade
        weth.approve(address(ethX), type(uint256).max);

        // create a flow
        cfaV1.createFlow(ALICE, ethX, 4206933);

        // approve operator permissions
        cfaV1.authorizeFlowOperatorWithFullControl(DEFAULT_FLOW_OPERATOR, ethX);
    }

    function assert_Flow_Rate_Is_Expected(
        address sender,
        address receiver,
        int96 expectedFlowRate
    ) public {
        (, int96 flowRate, , ) = cfaV1.cfa.getFlow(ethX, sender, receiver);
        assertEq(flowRate, expectedFlowRate);
    }

    function test_Polygon_Fork() public {
        assertEq(vm.activeFork(), polygonFork);
    }

    function test_Retrieve_Balance() public {
        uint256 balance = ethX.balanceOf(TEST_ACCOUNT);
    }

    function test_Downgrade() public {
        uint256 superTokenBalanceBefore = ethX.balanceOf(TEST_ACCOUNT);
        uint256 expectedBalance = superTokenBalanceBefore - 4206933;
        ethX.downgrade(4206933);
        uint256 superTokenBalanceAfter = ethX.balanceOf(TEST_ACCOUNT);
        assertEq(superTokenBalanceAfter, expectedBalance);
    }

    function test_Gas_Downgrade() public {
        ethX.downgrade(4206933);
    }

    function test_Upgrade() public {
        uint256 superTokenBalanceBefore = ethX.balanceOf(TEST_ACCOUNT);
        uint256 expectedBalance = superTokenBalanceBefore + 4206933;
        ethX.upgrade(4206933);
        uint256 superTokenBalanceAfter = ethX.balanceOf(TEST_ACCOUNT);
        assertEq(superTokenBalanceAfter, expectedBalance);
    }

    function test_Gas_Upgrade() public {
        ethX.upgrade(4206933);
    }

    function test_Create_Flow() public {
        cfaV1.createFlow(BOB, ethX, 4206933);
        assert_Flow_Rate_Is_Expected(TEST_ACCOUNT, BOB, 4206933);
    }

    function test_Update_Flow() public {
        cfaV1.updateFlow(ALICE, ethX, 694201337);
        assert_Flow_Rate_Is_Expected(TEST_ACCOUNT, ALICE, 694201337);
    }

    function test_Delete_Flow() public {
        cfaV1.deleteFlow(TEST_ACCOUNT, ALICE, ethX);
        assert_Flow_Rate_Is_Expected(TEST_ACCOUNT, ALICE, 0);
    }
    function test_Gas_Create_Flow() public {
        cfaV1.createFlow(BOB, ethX, 4206933);
    }

    function test_Gas_Update_Flow() public {
        cfaV1.updateFlow(ALICE, ethX, 4206933);
    }

    function test_Gas_Delete_Flow() public {
        cfaV1.deleteFlow(TEST_ACCOUNT, ALICE, ethX);
    }

    function test_Gas_Authorize_Flow_Operator_Permissions() public {
        cfaV1.authorizeFlowOperatorWithFullControl(ALICE, ethX);
    }

    function test_Gas_Revoke_Flow_Operator_Permissions() public {
        cfaV1.revokeFlowOperatorWithFullControl(DEFAULT_FLOW_OPERATOR, ethX);
    }

    function test_Gas_Create_Index() public {
        idaV1.createIndex(ethX, 1);
    }
}
