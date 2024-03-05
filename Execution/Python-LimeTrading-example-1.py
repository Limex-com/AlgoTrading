import time
from decimal import Decimal
import pprint
import sys

from lime_trader import LimeClient
from lime_trader.exceptions.api_error import ApiError
from lime_trader.models.page import PageRequest
from lime_trader.models.trading import Order, TimeInForce, OrderType, OrderSide

PERIOD_SHORT = 3
PERIOD_LONG = 18
DELTA_NS = 10 * 10000000  # 10 seconds
SYMBOL = "AAPL"
DZERO = Decimal(0)

K_SHORT = Decimal(2) / Decimal(PERIOD_SHORT + 1)
K_SHORT_INV = Decimal(1) - K_SHORT
K_LONG = Decimal(2) / Decimal(PERIOD_LONG + 1)
K_LONG_INV = Decimal(1) - K_LONG


def main():
    try:
        client = LimeClient.from_file(file_path="credentials.json")
        # initialize ema for short period
        ema_short = DZERO
        # initialize ema for long period
        ema_long = DZERO
        last_time = 0
        # need to get account numbers first
        while True:
            try:
                accounts = client.account.get_balances()
                print("accounts:", accounts)
                break
            except ApiError:
                print("ApiError on getting accounts:", str(sys.exc_info()))
                print("Going to sleep for a while and try later")
                time.sleep(1)
        # get account number of first account in a list
        account_number = accounts[0].account_number

        while True:
            cur_time = time.time_ns()
            # check time
            if cur_time - last_time >= DELTA_NS:
                try:
                    quote = client.market.get_current_quotes(symbols=[SYMBOL])[0]
                    print("quote:", quote)
                except ApiError:
                    print("error getting quotes:", str(sys.exc_info()))
                    time.sleep(1)
                    continue
                price = (quote.bid + quote.ask) / Decimal(2)
                # calculate new ema values
                ema_short_new = K_SHORT * price + K_SHORT_INV * ema_short
                ema_long_new = K_LONG * price + K_LONG_INV * ema_long
                print(
                    f"ema changes: short ema changed from {ema_short} to {ema_short_new}, long ema changed from {ema_long} to {ema_long_new}")
                try:
                    positions = client.account.get_positions(account_number=account_number)
                    print("pos:", positions)
                except ApiError:
                    print("error getting positions:", str(sys.exc_info()))
                    time.sleep(1)
                    continue
                # get pos of the security
                pos = next((p.quantity for p in positions if p.symbol == SYMBOL), 0)
                # check trade signals
                if pos <= 0 and ema_long > ema_short and ema_long_new <= ema_short_new:
                    # if position is opened, close it, else open new position
                    # we can`t close one posotion and open another by one order
                    quantity = -pos if pos < 0 else 1
                    # add buy order
                    order = Order(account_number=account_number,
                                  symbol=SYMBOL,
                                  quantity=Decimal(quantity),
                                  time_in_force=TimeInForce.DAY,
                                  order_type=OrderType.MARKET,
                                  side=OrderSide.BUY,
                                  exchange="auto",
                                  )
                    try:
                        placed_order_response = client.trading.place_order(order=order)
                        print("buy order result:", placed_order_response)
                    except ApiError:
                        print("error adding buy order:", str(sys.exc_info()))
                elif pos >= 0 and ema_long < ema_short and ema_long_new >= ema_short_new:
                    # if position is opened, close it, else open new position
                    # we can`t close one posotion and open another by one order
                    quantity = pos if pos > 0 else 1
                    # add sell order
                    order = Order(account_number=account_number,
                                  symbol=SYMBOL,
                                  quantity=Decimal(quantity),
                                  time_in_force=TimeInForce.DAY,
                                  order_type=OrderType.MARKET,
                                  side=OrderSide.SELL,
                                  exchange="auto",
                                  )
                    try:
                        placed_order_response = client.trading.place_order(order=order)
                        print("sell order result:", placed_order_response)
                    except ApiError:
                        print("error adding sell order:", str(sys.exc_info()))
                ema_short = ema_short_new
                ema_long = ema_long_new
                last_time = cur_time

            time.sleep(1)
    except KeyboardInterrupt:
        print("exiting")


if __name__ == "__main__":
    main()
