import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'transaction_details_view_model.g.dart';

class TransactionDetailsViewModel = TransactionDetailsViewModelBase
    with _$TransactionDetailsViewModel;

abstract class TransactionDetailsViewModelBase with Store {
  TransactionDetailsViewModelBase(
      {this.transactionInfo,
      this.transactionDescriptionBox,
      this.wallet,
      this.settingsStore})
      : items = [] {
    showRecipientAddress = settingsStore?.shouldSaveRecipientAddress ?? false;
    isRecipientAddressShown = false;

    final dateFormat = DateFormatter.withCurrentLocal();
    final tx = transactionInfo;

    if (wallet.type == WalletType.monero) {
      final key = tx.additionalInfo['key'] as String;
      final accountIndex = tx.additionalInfo['accountIndex'] as int;
      final addressIndex = tx.additionalInfo['addressIndex'] as int;
      final _items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        StandartListItem(
            title: S.current.transaction_details_fee, value: tx.feeFormatted()),
        if (key?.isNotEmpty ?? false)
          StandartListItem(title: S.current.transaction_key, value: key)
      ];

      if (tx.direction == TransactionDirection.incoming &&
          accountIndex != null &&
          addressIndex != null) {
        try {
          final address = monero.getTransactionAddress(wallet, accountIndex, addressIndex);

          if (address?.isNotEmpty ?? false) {
            isRecipientAddressShown = true;
            _items.add(
                StandartListItem(
                    title: S.current.transaction_details_recipient_address,
                    value: address));
          }
        } catch (e) {
          print(e.toString());
        }
      }

      items.addAll(_items);
    }

    if (wallet.type == WalletType.bitcoin
        || wallet.type == WalletType.litecoin) {
      final _items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.confirmations,
            value: tx.confirmations?.toString()),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        if (tx.feeFormatted()?.isNotEmpty)
          StandartListItem(
              title: S.current.transaction_details_fee,
              value: tx.feeFormatted()),
      ];

      items.addAll(_items);
    }

    if (showRecipientAddress && !isRecipientAddressShown) {
      final recipientAddress = transactionDescriptionBox.values
          .firstWhere((val) => val.id == transactionInfo.id, orElse: () => null)
          ?.recipientAddress;

      if (recipientAddress?.isNotEmpty ?? false) {
        items.add(StandartListItem(
            title: S.current.transaction_details_recipient_address,
            value: recipientAddress));
      }
    }

    final type = wallet.type;

    items.add(BlockExplorerListItem(
        title: "View in Block Explorer",
        value: _explorerDescription(type),
        onTap: () => launch(_explorerUrl(type, tx.id))));

    final description = transactionDescriptionBox.values.firstWhere(
        (val) => val.id == transactionInfo.id,
        orElse: () => TransactionDescription(id: transactionInfo.id));

    items.add(TextFieldListItem(
        title: S.current.note_tap_to_change,
        value: description.note,
        onSubmitted: (value) {
          description.transactionNote = value;

          if (description.isInBox) {
            description.save();
          } else {
            transactionDescriptionBox.add(description);
          }
        }));
  }

  final TransactionInfo transactionInfo;
  final Box<TransactionDescription> transactionDescriptionBox;
  final SettingsStore settingsStore;
  final WalletBase wallet;

  final List<TransactionDetailsListItem> items;
  bool showRecipientAddress;
  bool isRecipientAddressShown;

  String _explorerUrl(WalletType type, String txId) {
    switch (type) {
      case WalletType.monero:
        return 'https://xmrchain.net/search?value=${txId}';
      case WalletType.bitcoin:
        return 'https://www.blockchain.com/btc/tx/${txId}';
      case WalletType.litecoin:
        return 'https://blockchair.com/litecoin/transaction/${txId}';
      default:
        return '';
    }
  }

  String _explorerDescription(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return 'View Transaction on XMRChain.net';
      case WalletType.bitcoin:
        return 'View Transaction on Blockchain.com';
      case WalletType.litecoin:
        return 'View Transaction on Blockchair.com';
      default:
        return '';
    }
  }
}
