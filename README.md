# SequentialMetadataRenderer for Zora NFT Drop Media Contracts

- This repository is a fork of ourzora/zora-drops-contracts
- However, `src/metadata/SequentialMetadataRenderer.sol` and
  `test/metadata/SequentialMetadataRenderer.t.sol` are a modified version of
  EditionMetadataRenderer.
- They allow an initializer to set specific `MediaURIs` for a range of
  `tokenIds`, e.g. `tokenId=1-10` could have
  `imageURI=https://host.com/firstimage.jpg` whereas `tokenId=11-20` could have
  `imageURI=https://host.com/anotherimage.jpg`.
- We implemented this to retroactively change our [Kiwi News
  NFT](https://zora.co/collect/eth:0xebb15487787cbf8ae2ffe1a6cca5a50e63003786)
  minter's badges as we had frequently changed the imageURI but since Zora then
  refreshes the entire collection and not just the newly minted NFTs.
- We used `ERC721Drop.setMetadataRender` with a custom byte sequence to install
  the new metadata renderer (you can find the byte sequence generator as a unit
  test).
- From now on, our idea is to update the collection's `imageURI` more often as
  a way to promote our NFT collection by releasing new collectable badges every
  now and then
- Our contract is deployed at
  [eth:0x643198A532A1D5DE706E18E324234d9A6a70562A](https://etherscan.io/address/0x643198A532A1D5DE706E18E324234d9A6a70562A#code)
- License: GPL-3.0-only
