import {buildModule} from "@ignored/hardhat-ignition";
const {ethers} = require("hardhat");

const ACCOUNT_0 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

// @note comment out the libraries to run npx hardhat plan TestFrameworkModule

export default buildModule("TestFrameworkModule", (m) => {
    const host = m.contract("Superfluid", {args: [true, false]});
    const testGovernance = m.contract("TestGovernance");

    const cfaV1 = m.contract("ConstantFlowAgreementV1", {
        args: [host, ethers.constants.AddressZero],
    });
    // register cfa as an agreement class so it is trusted by the host
    const registerCFAv1 = m.call(testGovernance, "registerAgreementClass", {
        args: [host, cfaV1],
    });
    const cfaV1Forwarder = m.contract("CFAv1Forwarder", {
        args: [host],
        after: [registerCFAv1],
    });

    const slotsBitmapLibrary = m.library("SlotsBitmapLibrary");
    const idaV1 = m.contract("InstantDistributionAgreementV1", {
        args: [host],
        libraries: {SlotsBitmapLibrary: slotsBitmapLibrary},
    });

    // register ida as an agreement class so it is trusted by the host
    m.call(testGovernance, "registerAgreementClass", {
        args: [host, idaV1],
    });

    // deploy COF NFT logic contract
    const constantOutflowNFTLogic = m.contract("ConstantOutflowNFT", {
        args: [cfaV1],
    });
    
    // deploy CIF NFT logic contract
    const constantInflowNFTLogic = m.contract("ConstantInflowNFT", {
        args: [cfaV1],
    });

    const superfluidNFTDeployerLibrary = m.library(
        "SuperfluidNFTDeployerLibrary",
        {}
    );
    // Deploy SuperToken logic contract (holds the canonical NFT logic contracts-deterministically)
    const superTokenLogic = m.contract("SuperToken", {
        args: [host, constantOutflowNFTLogic, constantInflowNFTLogic],
        libraries: {SuperfluidNFTDeployerLibrary: superfluidNFTDeployerLibrary},
    });
    const superTokenFactory = m.contract("SuperTokenFactory", {
        args: [host, superTokenLogic],
    });
    const testResolver = m.contract("TestResolver", {args: [ACCOUNT_0]});

    const superfluidLoader = m.contract("SuperfluidLoader", {
        args: [testResolver],
    });

    // initialize governance in the host
    m.call(host, "initialize", {args: [testGovernance]});

    // set deployed contracts in the test resolver
    m.call(testResolver, "set", {
        args: ["TestGovernance.test", testGovernance],
    });
    m.call(testResolver, "set", {args: ["Superfluid.test", host]});
    m.call(testResolver, "set", {
        args: ["SuperfluidLoader-v1", superfluidLoader],
    });
    m.call(testResolver, "set", {args: ["CFAv1Forwarder", cfaV1Forwarder]});

    // initialize test governance
    m.call(testGovernance, "initialize", {
        args: [host, ACCOUNT_0, 4 * 60 * 60, 30 * 60, [] as any],
    });

    // update logic contracts in the test governance
    m.call(testGovernance, "updateContracts", {
        args: [host, ethers.constants.AddressZero, [], superTokenFactory],
    });

    return {
        host,
        testGovernance,
        cfaV1,
        cfaV1Forwarder,
        idaV1,
        superTokenFactory,
        superfluidLoader,
        testResolver,
    };
});
