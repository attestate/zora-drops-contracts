// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SequentialMetadataRenderer} from
  "../../src/metadata/SequentialMetadataRenderer.sol";
import {MetadataRenderAdminCheck} from
  "../../src/metadata/MetadataRenderAdminCheck.sol";
import {IMetadataRenderer} from "../../src/interfaces/IMetadataRenderer.sol";
import {NFTMetadataRenderer} from "../../src/utils/NFTMetadataRenderer.sol";
import {DropMockBase} from "./DropMockBase.sol";
import {IERC721Drop} from "../../src/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "../../src/ERC721Drop.sol";
import {Test, console} from "forge-std/Test.sol";

contract SequentialMetadataRendererMock is SequentialMetadataRenderer {
  function provisionTokenInfoExternal(address target)
    external
    view
    returns (uint256, TokenEditionInfo memory)
  {
    return provisionTokenInfo(target);
  }
}

interface IERC721 {
  function totalSupply() external view returns (uint256);
}

address constant location = 0xebB15487787cBF8Ae2ffe1a6Cca5a50E63003786;
ERC721Drop constant liveContract = ERC721Drop(payable(location));
IERC721 constant liveCollection = IERC721(location);

contract IERC721OnChainDataMock {
  IERC721Drop.SaleDetails private saleDetailsInternal;
  IERC721Drop.Configuration private configInternal;
  uint256 private totalSupplyInternal;

  constructor(uint256 totalMinted, uint256 maxSupply) {
    saleDetailsInternal = IERC721Drop.SaleDetails({
      publicSaleActive: false,
      presaleActive: false,
      publicSalePrice: 0,
      publicSaleStart: 0,
      publicSaleEnd: 0,
      presaleStart: 0,
      presaleEnd: 0,
      presaleMerkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
      maxSalePurchasePerAddress: 0,
      totalMinted: totalMinted,
      maxSupply: maxSupply
    });

    configInternal = IERC721Drop.Configuration({
      metadataRenderer: IMetadataRenderer(address(0x0)),
      editionSize: 12,
      royaltyBPS: 1000,
      fundsRecipient: payable(address(0x163))
    });
    totalSupplyInternal = totalMinted;
  }

  function name() external returns (string memory) {
    return "MOCK NAME";
  }

  function saleDetails() external returns (IERC721Drop.SaleDetails memory) {
    return saleDetailsInternal;
  }

  function config() external returns (IERC721Drop.Configuration memory) {
    return configInternal;
  }

  function totalSupply() external view returns (uint256) {
    return totalSupplyInternal;
  }

  function setTotalSupply(uint256 newTotalSupply) external {
    totalSupplyInternal = newTotalSupply;
  }
}

contract SequentialMetadataRendererTest is Test {
  SequentialMetadataRenderer public sequentialRenderer =
    new SequentialMetadataRenderer();
  IERC721OnChainDataMock public dropMock;

  constructor() public {
    dropMock = new IERC721OnChainDataMock(10, 100);
  }

  function test_updateDescription() public {
    uint256[] memory startTokenIds = new uint256[](2);
    startTokenIds[0] = 1;
    startTokenIds[1] = 3;

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](2);
    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 1",
      imageURI: "https://example.com/image1.png",
      animationURI: "https://example.com/animation1.mp4"
    });
    infos[1] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 2",
      imageURI: "https://example.com/image2.png",
      animationURI: "https://example.com/animation2.mp4"
    });
    bytes memory data = abi.encode(startTokenIds, infos);
    vm.startPrank(address(dropMock));
    sequentialRenderer.initializeWithData(data);

    dropMock.setTotalSupply(4);

    string memory newDescription = "New Description";
    sequentialRenderer.updateDescription(address(dropMock), newDescription);

    string memory expectedUri1 = NFTMetadataRenderer.createMetadataEdition({
      name: dropMock.name(),
      description: newDescription,
      imageURI: infos[1].imageURI,
      animationURI: infos[1].animationURI,
      tokenOfEdition: 5,
      editionSize: 100
    });

    string memory uri1 = sequentialRenderer.tokenURI(5);
    assertEq(uri1, expectedUri1);

    string memory expectedUri2 = NFTMetadataRenderer.createMetadataEdition({
      name: dropMock.name(),
      description: infos[1].description,
      imageURI: infos[1].imageURI,
      animationURI: infos[1].animationURI,
      tokenOfEdition: 4,
      editionSize: 100
    });

    string memory uri2 = sequentialRenderer.tokenURI(4);
    assertEq(uri2, expectedUri2);
  }

  function test_updateMediaURIs() public {
    uint256[] memory startTokenIds = new uint256[](2);
    startTokenIds[0] = 1;
    startTokenIds[1] = 3;

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](2);
    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 1",
      imageURI: "https://example.com/image1.png",
      animationURI: "https://example.com/animation1.mp4"
    });
    infos[1] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 2",
      imageURI: "https://example.com/image2.png",
      animationURI: "https://example.com/animation2.mp4"
    });
    bytes memory data = abi.encode(startTokenIds, infos);
    vm.startPrank(address(dropMock));
    sequentialRenderer.initializeWithData(data);

    dropMock.setTotalSupply(4);

    string memory newImageURI = "https://example.com/new_image.png";
    string memory newAnimationURI = "https://example.com/new_animation.mp4";
    sequentialRenderer.updateMediaURIs(
      address(dropMock), newImageURI, newAnimationURI
    );

    string memory expectedUri1 = NFTMetadataRenderer.createMetadataEdition({
      name: dropMock.name(),
      description: infos[1].description,
      imageURI: newImageURI,
      animationURI: newAnimationURI,
      tokenOfEdition: 5,
      editionSize: 100
    });

    string memory uri1 = sequentialRenderer.tokenURI(5);
    assertEq(uri1, expectedUri1);

    string memory expectedUri2 = NFTMetadataRenderer.createMetadataEdition({
      name: dropMock.name(),
      description: infos[1].description,
      imageURI: infos[1].imageURI,
      animationURI: infos[1].animationURI,
      tokenOfEdition: 4,
      editionSize: 100
    });

    string memory uri2 = sequentialRenderer.tokenURI(4);
    assertEq(uri2, expectedUri2);
  }

  function test_initializeWithData() public {
    uint256[] memory startTokenIds = new uint256[](2);
    startTokenIds[0] = 1;
    startTokenIds[1] = 3;

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](2);

    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 1",
      imageURI: "https://example.com/image1.png",
      animationURI: "https://example.com/animation1.mp4"
    });

    infos[1] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 2",
      imageURI: "https://example.com/image2.png",
      animationURI: "https://example.com/animation2.mp4"
    });

    bytes memory data = abi.encode(startTokenIds, infos);

    vm.startPrank(address(liveContract));
    sequentialRenderer.initializeWithData(data);

    IERC721Drop.SaleDetails memory details = liveContract.saleDetails();

    string memory expectedUri1 = NFTMetadataRenderer.createMetadataEdition({
      name: liveContract.name(),
      description: infos[0].description,
      imageURI: infos[0].imageURI,
      animationURI: infos[0].animationURI,
      tokenOfEdition: 1,
      editionSize: 0
    });

    string memory expectedUri2 = NFTMetadataRenderer.createMetadataEdition({
      name: liveContract.name(),
      description: infos[0].description,
      imageURI: infos[0].imageURI,
      animationURI: infos[0].animationURI,
      tokenOfEdition: 2,
      editionSize: 0
    });

    string memory expectedUri3 = NFTMetadataRenderer.createMetadataEdition({
      name: liveContract.name(),
      description: infos[1].description,
      imageURI: infos[1].imageURI,
      animationURI: infos[1].animationURI,
      tokenOfEdition: 3,
      editionSize: 0
    });

    string memory uri1 = sequentialRenderer.tokenURI(1);
    assertEq(uri1, expectedUri1);

    string memory uri2 = sequentialRenderer.tokenURI(2);
    assertEq(uri2, expectedUri2);

    string memory uri3 = sequentialRenderer.tokenURI(3);
    assertEq(uri3, expectedUri3);
  }

  function test_initializeWithData_OnlyOnce() public {
    uint256[] memory startTokenIds = new uint256[](1);
    startTokenIds[0] = 0;

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](1);

    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 1",
      imageURI: "https://example.com/image1.png",
      animationURI: "https://example.com/animation1.mp4"
    });

    bytes memory data = abi.encode(startTokenIds, infos);

    vm.startPrank(address(dropMock));
    sequentialRenderer.initializeWithData(data);

    vm.expectRevert(
      SequentialMetadataRenderer.Invariant_AlreadyInitialized.selector
    );
    sequentialRenderer.initializeWithData(data);
  }

  function test_provisionTokenInfo_WithNoStartTokens() public {
    SequentialMetadataRendererMock rendererMock =
      new SequentialMetadataRendererMock();
    address target = address(0x1);
    vm.startPrank(target);
    vm.expectRevert(
      abi.encodeWithSelector(
        SequentialMetadataRenderer.Invariant_NotInitialized.selector
      )
    );
    rendererMock.provisionTokenInfoExternal(target); // This call is expected to revert
  }

  function test_provisionTokenInfo_AfterInitializeWithData() public {
    SequentialMetadataRendererMock rendererMock =
      new SequentialMetadataRendererMock();
    uint256[] memory startTokenIds = new uint256[](1);
    startTokenIds[0] = liveCollection.totalSupply();

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](1);

    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: "Description for metadata 1",
      imageURI: "https://example.com/image1.png",
      animationURI: "https://example.com/animation1.mp4"
    });

    bytes memory data = abi.encode(startTokenIds, infos);
    rendererMock.initializeWithData(data); // Initializing data

    uint256 totalSupply = liveCollection.totalSupply();
    (
      uint256 newStartToken,
      SequentialMetadataRenderer.TokenEditionInfo memory oldTokenInfo
    ) = rendererMock.provisionTokenInfoExternal(address(liveContract));

    assertEq(newStartToken, totalSupply + 1);
    assertEq(oldTokenInfo.description, infos[0].description);
    assertEq(oldTokenInfo.imageURI, infos[0].imageURI);
    assertEq(oldTokenInfo.animationURI, infos[0].animationURI);
  }

  function test_initializeWithDataAndCheckTokenURIs() public {
    vm.startPrank(0xee324c588ceF1BF1c1360883E4318834af66366d);

    uint256[] memory startTokenIds = new uint256[](3);
    startTokenIds[0] = 1;
    startTokenIds[1] = 49;
    startTokenIds[2] = 85;

    SequentialMetadataRenderer.TokenEditionInfo[] memory infos =
      new SequentialMetadataRenderer.TokenEditionInfo[](3);

    infos[0] = SequentialMetadataRenderer.TokenEditionInfo({
      description: unicode"Go to https://kiwinews.xyz/ for your daily dose of kiwi 🥝",
      imageURI: "ipfs://bafkreierdgazvr3olgitxjhhspmb2dsyzaqti5nqegxb5rjoixzs6y6sc4",
      animationURI: ""
    });

    infos[1] = SequentialMetadataRenderer.TokenEditionInfo({
      description: unicode"Go to https://kiwinews.xyz/ for your daily dose of kiwi 🥝",
      imageURI: "ipfs://bafkreia7evclnh6kulq6lozxkepvhy6j54kxutsheump3gvypgrcykaube",
      animationURI: ""
    });

    infos[2] = SequentialMetadataRenderer.TokenEditionInfo({
      description: unicode"Go to https://kiwinews.xyz/ for your daily dose of kiwi 🥝",
      imageURI: "ipfs://bafkreiepes37ey3cntyuyrhjyht5qjre4ub7tojxif3x66bf2gmnexviqi",
      animationURI: ""
    });

    bytes memory data = abi.encode(startTokenIds, infos);
    console.logBytes(data);

    liveContract.setMetadataRenderer(
      IMetadataRenderer(address(sequentialRenderer)), data
    );

    vm.stopPrank();
    vm.startPrank(address(liveContract));
    for (uint256 i = 1; i <= 107; i++) {
      string memory expectedUri = NFTMetadataRenderer.createMetadataEdition({
        name: liveContract.name(),
        description: infos[getInfoIndex(i)].description,
        imageURI: infos[getInfoIndex(i)].imageURI,
        animationURI: infos[getInfoIndex(i)].animationURI,
        tokenOfEdition: i,
        editionSize: 0
      });
      string memory uri = sequentialRenderer.tokenURI(i);
      assertEq(uri, expectedUri);
    }
  }

  function getInfoIndex(uint256 tokenId) internal pure returns (uint256) {
    if (tokenId <= 48) {
      return 0;
    } else if (tokenId <= 84) {
      return 1;
    } else {
      return 2;
    }
  }
}
