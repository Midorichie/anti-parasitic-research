import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures that project creation works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall(
                'parasitic-research-funding',
                'create-project',
                [
                    types.ascii("Test Project"),
                    types.ascii("A test research project"),
                    types.uint(1000000)
                ],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectUint(0);
    },
});

Clarinet.test({
    name: "Ensures that milestone creation works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const validator = accounts.get('wallet_1')!;
        
        // First create a project
        let block = chain.mineBlock([
            Tx.contractCall(
                'parasitic-research-funding',
                'create-project',
                [
                    types.ascii("Test Project"),
                    types.ascii("A test research project"),
                    types.uint(1000000)
                ],
                deployer.address
            ),
            // Then add a milestone
            Tx.contractCall(
                'parasitic-research-funding',
                'add-milestone',
                [
                    types.uint(0),
                    types.ascii("First research phase"),
                    types.uint(500000),
                    types.principal(validator.address)
                ],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts.length, 2);
        block.receipts[0].result.expectOk().expectUint(0);
        block.receipts[1].result.expectOk().expectUint(0);
    },
});

Clarinet.test({
    name: "Ensures unauthorized users cannot approve milestones",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const validator = accounts.get('wallet_1')!;
        const unauthorized = accounts.get('wallet_2')!;
        
        // Setup: Create project and milestone
        let setup = chain.mineBlock([
            Tx.contractCall(
                'parasitic-research-funding',
                'create-project',
                [
                    types.ascii("Test Project"),
                    types.ascii("A test research project"),
                    types.uint(1000000)
                ],
                deployer.address
            ),
            Tx.contractCall(
                'parasitic-research-funding',
                'add-milestone',
                [
                    types.uint(0),
                    types.ascii("First research phase"),
                    types.uint(500000),
                    types.principal(validator.address)
                ],
                deployer.address
            )
        ]);
        
        // Test: Attempt unauthorized milestone approval
        let block = chain.mineBlock([
            Tx.contractCall(
                'parasitic-research-funding',
                'approve-milestone',
                [
                    types.uint(0),
                    types.uint(0)
                ],
                unauthorized.address
            )
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectErr().expectUint(100); // ERR-NOT-AUTHORIZED
    },
});
