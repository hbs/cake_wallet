import 'dart:async';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';

part 'order_details_view_model.g.dart';

class OrderDetailsViewModel = OrderDetailsViewModelBase
    with _$OrderDetailsViewModel;

abstract class OrderDetailsViewModelBase with Store {
  OrderDetailsViewModelBase({WalletBase wallet, Order orderForDetails}) {
    order = orderForDetails;

    if (order.provider != null) {
      switch (order.provider) {
        case BuyProviderDescription.wyre:
          _provider = WyreBuyProvider(wallet: wallet);
          break;
        case BuyProviderDescription.moonPay:
          _provider = MoonPayBuyProvider(wallet: wallet);
          break;
      }
    }

    items = ObservableList<StandartListItem>();

    _updateItems();

    _updateOrder();

    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateOrder());
  }

  @observable
  Order order;

  @observable
  ObservableList<StandartListItem> items;

  BuyProvider _provider;

  Timer timer;

  @action
  Future<void> _updateOrder() async {
    try {
      if (_provider != null) {
        final updatedOrder = await _provider.findOrderById(order.id);
        updatedOrder.from = order.from;
        updatedOrder.to = order.to;
        updatedOrder.receiveAddress = order.receiveAddress;
        updatedOrder.walletId = order.walletId;
        if (order.provider != null) {
          updatedOrder.providerRaw = order.provider.raw;
        }
        order = updatedOrder;
        _updateItems();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();

    items?.clear();

    items.addAll([
      StandartListItem(
          title: 'Transfer ID',
          value: order.transferId),
      StandartListItem(
          title: S.current.trade_details_state,
          value: order.state != null
              ? order.state.toString()
              : S.current.trade_details_fetching),
    ]);

    if (order.provider != null) {
      items.add(
        StandartListItem(
            title: 'Buy provider',
            value: order.provider.title)
      );
    }

    if (_provider?.trackUrl?.isNotEmpty ?? false) {
      final buildURL = _provider.trackUrl + '${order.transferId}';
      items.add(
        TrackTradeListItem(
            title: 'Track',
            value: buildURL,
            onTap: () => launch(buildURL)
        )
      );
    }

    items.add(
        StandartListItem(
            title: S.current.trade_details_created_at,
            value: dateFormat.format(order.createdAt).toString())
    );

    items.add(
        StandartListItem(
            title: S.current.trade_details_pair,
            value: '${order.from} → ${order.to}')
    );
  }
}