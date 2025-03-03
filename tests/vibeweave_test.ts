import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Can remove song from playlist",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Test Playlist"),
        types.ascii("Test Description"),
        types.ascii("Test")
      ], deployer.address),
      
      Tx.contractCall('vibeweave', 'add-song', [
        types.uint(1),
        types.ascii("Test Song"),
        types.ascii("Test Artist"),
        types.uint(180)
      ], deployer.address),
      
      Tx.contractCall('vibeweave', 'remove-song', [
        types.uint(1),
        types.uint(1)
      ], deployer.address)
    ]);
    
    block.receipts[2].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Can transfer playlist ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Test Playlist"),
        types.ascii("Test Description"),
        types.ascii("Test")
      ], deployer.address),
      
      Tx.contractCall('vibeweave', 'transfer-playlist-ownership', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    block.receipts[1].result.expectOk().expectBool(true);
  }
});
