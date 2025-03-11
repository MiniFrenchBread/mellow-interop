// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.25;

import "../src/core/SourceCore.sol";
import "./DeployLibrary.sol";
import {
    EnforcedOptionParam,
    IOAppOptionsType3
} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract SourceDeployScript {
    using OptionsBuilder for bytes;

    address public immutable targetEndpoint;
    uint32 public immutable targetEid;
    address public immutable targetDeployScript;
    address public immutable targetDelegator;

    address public immutable sourceEndpoint;
    address public immutable sourceCoreSingleton;

    constructor(
        address targetEndpoint_,
        uint32 targetEid_,
        address targetDeployScript_,
        address targetDelegator_,
        address sourceEndpoint_,
        address sourceCoreSingleton_
    ) {
        targetEndpoint = targetEndpoint_;
        targetEid = targetEid_;
        targetDeployScript = targetDeployScript_;
        targetDelegator = targetDelegator_;
        sourceEndpoint = sourceEndpoint_;
        sourceCoreSingleton = sourceCoreSingleton_;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    struct DeployParams {
        address token;
        bytes32 salt;
        string name;
        string symbol;
        address admin;
        address operator;
        address proxyAdmin;
        uint256 limit;
        uint256 epochDuration;
        uint256 withdrawalDelay;
        uint256 maxAge;
    }

    function deploy(DeployParams calldata params)
        external
        returns (MellowOFTAdapter oftAdapter, SourceCore sourceCore)
    {
        oftAdapter =
            MellowOFTAdapter(DeployLibrary.deployOFTAdapter(params.token, sourceEndpoint, address(this), params.salt));
        address expectedMellowOFT = DeployLibrary.computeOFTAddress(
            params.name, params.symbol, targetEndpoint, targetDeployScript, params.salt, targetDeployScript
        );
        address expectedTargetCore = address(0);

        oftAdapter.setPeer(targetEid, addressToBytes32(address(expectedMellowOFT)));
        {
            EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](1);
            enforcedOptions[0] = EnforcedOptionParam({
                eid: targetEid,
                msgType: oftAdapter.SEND(),
                options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(1e6, 0)
            });
            IOAppOptionsType3(oftAdapter).setEnforcedOptions(enforcedOptions);
        }
        sourceCore = SourceCore(
            address(
                new TransparentUpgradeableProxy{salt: params.salt}(
                    sourceCoreSingleton,
                    params.proxyAdmin,
                    abi.encodeCall(
                        SourceCore.initialize,
                        (
                            ISourceCoreStorage.InitParams({
                                admin: address(this),
                                name: params.name,
                                symbol: params.symbol,
                                mellowOFTAdapter: address(oftAdapter),
                                epochDuration: params.epochDuration,
                                targetEndpointId: targetEid,
                                targetCoreAddress: addressToBytes32(expectedTargetCore),
                                limit: params.limit,
                                pushRoleHolder: params.operator,
                                setWithdrawalDelayRoleHolder: address(this),
                                setValueRoleHolder: address(this),
                                setMaxAgeRoleHolder: address(this),
                                setLimitRoleHolder: params.admin
                            })
                        )
                    )
                )
            )
        );

        Oracle oracle = Oracle(sourceCore.oracle());
        oracle.setMaxAge(params.maxAge);
        oracle.setValue(1 ether);

        sourceCore.grantRole(sourceCore.DEFAULT_ADMIN_ROLE(), params.admin);
        sourceCore.grantRole(sourceCore.SET_LIMIT_ROLE(), params.setLimitRoleHolder);
        sourceCore.grantRole(oracle.SET_MAX_AGE_ROLE(), params.setMaxAgeRoleHolder);
        sourceCore.grantRole(sourceCore.SET_VALUE_ROLE(), params.adminw);

        sourceCore.renounceRole(sourceCore.DEFAULT_ADMIN_ROLE(), address(this));
        sourceCore.renounceRole(sourceCore.SET_LIMIT_ROLE(), address(this));
        sourceCore.renounceRole(oracle.SET_MAX_AGE_ROLE(), address(this));
        sourceCore.renounceRole(sourceCore.SET_VALUE_ROLE(), address(this));

        mellowOFTAdapter.transferOwnership(params.admin);
    }
}
