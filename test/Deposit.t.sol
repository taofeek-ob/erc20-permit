// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/SigUtils.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    /*//////////////////////////////////////////////////////////////
                             LOAD CONTRACTS
    //////////////////////////////////////////////////////////////*/
    MockERC20 public token;
    SigUtils public sigUtils;
    TokenBank public tokenBank;

    /*//////////////////////////////////////////////////////////////
                             PRIVATE KEYS FOR OWNER AND SPENDER
//////////////////////////////////////////////////////////////*/
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    /*//////////////////////////////////////////////////////////////
                             TEST SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        token = new MockERC20();
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
        tokenBank = new TokenBank();

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        spender = vm.addr(spenderPrivateKey);
        owner = vm.addr(ownerPrivateKey);

        token.mint(owner, 1e18);
        token.mint(address(this), 1e18);
    }

    function testDeposit() public {
        token.approve(address(tokenBank), 1e18);

        tokenBank.deposit(address(token), 5e17);

        assertEq(token.balanceOf(address(this)), 5e17);
        assertEq(token.balanceOf(address(tokenBank)), 5e17);

        assertEq(token.allowance(address(this), address(tokenBank)), 5e17);
        assertEq(tokenBank.userDeposits(address(this), address(token)), 5e17);
    }

    function test_DepositWithPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: address(tokenBank),
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        tokenBank.depositWithPermit(
            address(token),
            permit.value,
            owner,
            address(tokenBank),
            permit.value,
            1 days,
            v,
            r,
            s
        );

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(address(tokenBank)), 1e18);

        assertEq(token.allowance(owner, address(tokenBank)), 0);
        assertEq(token.nonces(owner), 1);

        assertEq(tokenBank.userDeposits(owner, address(token)), 1e18);
    }

    function test_DepositWithMaxPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: address(tokenBank),
            value: type(uint256).max,
            nonce: token.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        tokenBank.depositWithPermit(
            address(token),
            1e18,
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(address(tokenBank)), 1e18);

        assertEq(token.allowance(owner, address(tokenBank)), type(uint256).max);
        assertEq(token.nonces(owner), 1);

        assertEq(tokenBank.userDeposits(owner, address(token)), 1e18);
    }
}
