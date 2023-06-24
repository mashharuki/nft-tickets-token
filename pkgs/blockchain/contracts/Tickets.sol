// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * Tickets Token
 */
contract Tickets is ERC721, Ownable {

  // PriceRecord型の変数
  struct PriceRecord {
    uint32 validTo;
    uint96 price;
  }

  uint256[] internal tokenPrices;
  PriceRecord[] public priceRecords;
  // 販売中止期間中の値段
  uint96 public constant INVALID_PRICE = type(uint96).max;

  /**
   * コンストラクター
   */
  constructor() ERC721("Sample NFT", "SNT")  {}

  // ========= setter  ==========

  /**
   * 新しくチケットの値段の情報を追記するためのメソッド
   * @param validTo 有効期限
   * @param price チケット代
   */
  function _pushPrice(uint256 validTo, uint256 price) private {
    priceRecords.push(
      PriceRecord({
        validTo: uint32(validTo),
        price: price >= INVALID_PRICE ? INVALID_PRICE : uint96(price)
      })
    );
  }

  /**
   * 価格を設定するメソッド
   */
  function setPrice(uint256 validTo, uint256 price) public onlyOwner {
    require(validTo > block.number, "Past price update rejected");

    uint96 lastPrice = INVALID_PRICE;
    PriceRecord memory priceRecord;
    uint256 i;

    for (i = priceRecords.length; i > 0; i--) {
      priceRecord = priceRecords[i - 1];

      if (priceRecord.validTo < validTo) {
        break;
      }

      lastPrice = priceRecord.price;
      priceRecords.pop();
    }

    if ((i == 0 || priceRecord.validTo < block.number) && lastPrice != price) {
      _pushPrice(block.number, lastPrice);
    }
    _pushPrice(validTo, price);
  }

  /**
   * チケットを購入するためのメソッド
   */
  function purchase() public payable {
    require(isOnSale(), "Not on sale");
    require(balanceOf(_msgSender()) == 0, "Already purchased");

    uint256 currentPrice = getCurrentPrice();
    require(msg.value >= currentPrice, "Insufficient fund");

    tokenPrices.push(currentPrice);
    uint256 tokenId = tokenPrices.length;
    // 呼び出し元アドレスに対してNFTをミントする。
    _safeMint(_msgSender(), tokenId);
  }

  /**
   * 払い戻しのためのメソッド
   */
  function refund(uint256 tokenId) public {
    require(isOnSale(), "Refund available only while on sale");
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "Caller is not owner nor approved"
    );

    uint256 tokenPrice = tokenPrices[tokenId - 1];
    delete tokenPrices[tokenId - 1];

    uint256 refundAmount = tokenPrice >> 1;
    address payable recipient = payable(ownerOf(tokenId));

    _burn(tokenId);
    recipient.transfer(refundAmount);
  }

  function firstTokenOfOwner(address owner) public view returns (uint256 ret) {
    require(balanceOf(owner) > 0, "Not a token owner");

    uint256 count = tokenPrices.length;

    for (uint256 i = 0; i++ < count; ) {
      if (_exists(i) && ownerOf(i) == owner) {
        return i;
      }
    }

    assert(false);
    return 0;
  }

  // ========= getter  ==========

  function totalPriceRecords() public view returns (uint256) {
    return priceRecords.length;
  }

  /**
   * 現在のチケット代を取得するメソッド
   */
  function getCurrentPrice() public view returns (uint256) {
    return getPrice(block.number);
  }

  /**
   * 引数に渡されたblockNumberの値に基づいてチケット代を取得するメソッド
   */
  function getPrice(uint256 blockNumber) public view returns (uint256) {
    // 現在のレコード数を取得する。
    uint256 priceRecordCount = priceRecords.length;

    for (uint256 i = 0; i < priceRecordCount; i++) {
      PriceRecord memory priceRecord = priceRecords[i];

      if (blockNumber <= priceRecord.validTo) {
        return priceRecord.price;
      }
    }

    return INVALID_PRICE;
  }

  function isOnSale() public view returns (bool) {
    return getPrice(block.number) < INVALID_PRICE;
  }

  /**
   * _beforeTokenTransferメソッドをオーバーライドして販売中かどうかをチェックする
   */
  function _beforeTokenTransfer(address from, address to, uint256, uint256) internal view override {
    require(!isOnSale() || from == address(0) || to == address(0));
  }
}
