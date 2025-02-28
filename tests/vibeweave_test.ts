import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new playlist with category",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Summer Party"),
        types.ascii("Awesome summer vibes playlist"),
        types.ascii("Party")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Can toggle playlist status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Test Playlist"),
        types.ascii("Test Description"),
        types.ascii("Test")
      ], deployer.address),
      
      Tx.contractCall('vibeweave', 'toggle-playlist-status', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk().expectBool(true);
  }
});
