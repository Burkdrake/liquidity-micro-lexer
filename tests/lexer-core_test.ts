import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
  name: "Liquidity Micro-Lexer: Participant Profile Management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;

    let block = chain.mineBlock([
      Tx.contractCall('lexer-core', 'update-participant-profile', 
        [
          types.some(types.utf8('TestUser')),
          types.some(types.utf8('https://example.com/profile'))
        ], 
        participant.address
      )
    ]);

    // Initial profile update test
    assertEquals(block.receipts[0].result, '(ok true)');

    // Retrieve profile to verify
    let profileResult = chain.callReadOnlyFn(
      'lexer-core', 
      'get-participant-profile', 
      [types.principal(participant.address)], 
      participant.address
    );

    assertEquals(
      profileResult.result, 
      '(some {active: true, alias: (some "TestUser"), metadata-url: (some "https://example.com/profile"), registration-timestamp: u0})'
    );
  }
});

Clarinet.test({
  name: "Liquidity Micro-Lexer: Resource Type Registration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('lexer-core', 'register-resource-type', 
        [
          types.utf8('analytics'),
          types.utf8('Performance Analytics'),
          types.utf8('Aggregate performance metrics'),
          types.uint(2)
        ], 
        deployer.address
      )
    ]);

    // Resource type registration test
    assertEquals(block.receipts[0].result, '(ok true)');

    // Verify resource type details
    let resourceTypeResult = chain.callReadOnlyFn(
      'lexer-core', 
      'get-resource-type-details', 
      [types.utf8('analytics')], 
      deployer.address
    );

    assertEquals(
      resourceTypeResult.result, 
      '(some {name: "Performance Analytics", description: "Aggregate performance metrics", confidentiality-level: u2})'
    );
  }
});