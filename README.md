# erc20-permit
A sample template for using ERC-712 Permit for `token.transferFrom()` in a single transaction, without requiring a preceedinga `approval()`. A sample mock `TokenBank` contract also shows a a third party implementation.

ERC-20 is based on solmate, and developmet environment is foundry.

Test can be found in the test directory, and run suing `forge test`
