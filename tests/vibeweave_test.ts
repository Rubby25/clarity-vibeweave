import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new playlist as owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Summer Party"),
        types.ascii("Awesome summer vibes playlist")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Can add and vote on songs",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Create playlist
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Party Mix"),
        types.ascii("Party playlist")
      ], deployer.address),
      
      // Add song
      Tx.contractCall('vibeweave', 'add-song', [
        types.uint(1),
        types.ascii("Dancing Queen"),
        types.ascii("ABBA")
      ], user1.address),
      
      // Vote on song
      Tx.contractCall('vibeweave', 'vote-song', [
        types.uint(1),
        types.uint(1)
      ], user1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    block.receipts[1].result.expectOk().expectUint(1);
    block.receipts[2].result.expectOk().expectBool(true);
    
    // Check song info
    let songInfo = chain.mineBlock([
      Tx.contractCall('vibeweave', 'get-song-info', [
        types.uint(1),
        types.uint(1)
      ], deployer.address)
    ]);
    
    let song = songInfo.receipts[0].result.expectOk().expectSome();
    assertEquals(song['votes'].expectUint(1), 1);
  }
});

Clarinet.test({
  name: "Can manage moderators",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Create playlist
      Tx.contractCall('vibeweave', 'create-playlist', [
        types.ascii("Mod Test"),
        types.ascii("Testing moderators")
      ], deployer.address),
      
      // Add moderator
      Tx.contractCall('vibeweave', 'add-moderator', [
        types.uint(1),
        types.principal(user1.address)
      ], deployer.address),
      
      // Check moderator status
      Tx.contractCall('vibeweave', 'is-user-moderator', [
        types.uint(1),
        types.principal(user1.address)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectOk().expectBool(true);
  }
});