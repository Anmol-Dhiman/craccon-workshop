## Test Commands
- Re-entrancy
```bash
forge test --mt testReentrancyAttack -vvvv
```

- DoS
```bash
forge test --mt testDoSAttack -vvvv
```

- GasGrefing
```bash
forge test --mt testGasGriefingAttack -vvvv
```

- OverUnderFlow
```bash
forge test --mt testOverflow -vvvv
```

```bash
forge test --mt testUnderflow -vvvv
```

- SignatureReplay
```bash
forge test --mt testReplayAttack -vvvv
```


## Get Storage Slot Value of on-Chain contract
```bash
curl -X POST \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getStorageAt",
    "params":[
      "0xContractAddress",
      "0xSlotIndex",
      "latest"
    ],
    "id":1
  }' \
  -H "Content-Type: application/json" \
  https://your-rpc-url.com

```


- Smart Contract Storage Layout
https://tintinweb.github.io/smart-contract-storage-viewer/