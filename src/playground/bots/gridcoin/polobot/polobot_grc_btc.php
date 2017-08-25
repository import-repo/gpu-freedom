<?php
	// A simple arbitrage trading bot (a taker bot)
	// (c) by 2017 dangermouse, GPL licence
	// API reference is at https://poloniex.com/support/api/

	
	require_once("poloniex_api.php");
        require_once("conf/config.inc.php");	

	$date = date('Y-m-d H:i:s');
	echo "$date\n";
	

	// fee structure
	$fee_maker = 0.0015;
	$fee_taker = 0.0025;
	
	// currency to be traded
	$currency_1 = "GRC";
	$max_tradable_1 = 100; // maximum amount tradable in currency 1

	$tradable_amount_1 = $max_tradable_1/10.0; // tradable amount when setting order
	
	$currency_2 = "BTC";
    $max_tradable_2 = 0.01; // maximum amount tradable in currency 2
	//TODO: remove me
	//$tradable_amount_2 = $max_tradable_2/10.0; // tradable amount when setting order
	
	$currency_ref = "USDT"; // tether as reference currency to maximize portfolio
        

	// currency pairs
	$curpair_1_2 = $currency_1 . "_" . $currency_2;
	$curpair_2_ref = $currency_2 . "_" . $currency_ref;
        
        echo "API key: ";
        echo $my_api_key;
        echo "\n";
        echo "API secret: ";
        echo $my_api_secret;
        echo "\n";

        
	$api = new poloniex($my_api_key, $my_api_secret);
	
	// 0. cancel existing orders lying around from previous bot calls 
	// (they lay around for example if the order could be only partially fullfilled)
	// get_open_orders($pair), retrieves ordernumber
	// iterate over and do cancel_order($pair, $order_number)
	/*
        TODO: enable me
        $openorders = $api -> get_open_orders($curpair_1_2)
	for (int i=0; i<count($openorders); i++) {
			$api-> cancel_order($curpair_1_2, $openorders[i]["orderNumber"]);
	}
        */
   
	
	// 1. retrieve current prices
	// TODO: retrieve also bid and ask to be more accurate (using lowestAsk and highestBid)
	//echo $curpair_1_2;
        $res = $api->get_ticker($curpair_1_2);
        echo $res["GRC_BTC"]["last"];
        //$price_1_in_2 = ($api->get_ticker($curpair_1_2)->"last"); //["last"];
        //echo "\n£";
        //echo $price_1_in_2;
	//echo "£\n";
        //$price_2_in_ref = ($api->get_ticker($curpair_2_ref))["last"];
	//$price_1_in_ref = $price_1_in_2 * $price_2_in_ref;
	
	//echo "$price_1_in_ref $currency_1/$currency_ref      $price_2_in_ref $currency_2/$currency_ref      $price_1_in_2 $currency_1/$currency_2   \n";
	
	/*
	// 2. retrieve our current balance in currency 1 and 2
	//    and calculate current portfolio value in reference currency
	$balances = $api->get_balances();
	$balance_cur_1 = min($balances[$currency_1],$max_tradable_1);
	$balance_cur_2 = min($balances[$currency_2],$max_tradable_2);
	
	$cur_portfolio_value_ref = ($balance_cur_1 * $price_1_in_ref) + ($balance_cur_2 * $price_2_in_ref);
	
	echo "$balance_cur_1 $currency_1  +   $balance_cur_2 $currency_2      ->    $cur_portfolio_value_ref $currency_ref";
	
	// 3. now go through order book and see which order would maximize our portfolio value in ref currency
	$orderbook = $api->get_order_book($curpair_1_2);
	$bestbid = $orderbook["bids"][0]; // best offer when we want to sell
	$bestask = $orderbook["ask"][0]; // best offer when we want to buy
	
	// 4. now we check if selling the tradable amount makes our portfolio look better in refcurrency
	if (($balance_cur_1 - $tradable_amount_1)>0) {
		$new_portfolio_value_ref_sell = (($balance_cur_1 - $tradable_amount_1) * $price_1_in_ref) + // balance in currency 1 is decreased
		                           (($balance_cur_2 + $tradable_amount_1*$bestbid  ) * $price_2_in_ref) // balance in currency 2 is increased
		                           - ($tradable_amount_1*$bestbid*$fee_taker) * $price_2_in_ref;  // fees
								   
	}
	
	// 5. specularly we check if buying the tradable amount makes our portfolio look better in refcurrency
	if (($balance_cur_2 - $tradable_amount_1*$bestask)>0) {
		$new_portfolio_value_ref_buy = (($balance_cur_1 + $tradable_amount_1) * $price_1_in_ref) + // balance in currency 1 is increased
		                           (($balance_cur_2 - $tradable_amount_1*$bestask  ) * $price_2_in_ref) // balance in currency 2 is decreased
		                           - ($tradable_amount_1*$bestask*$fee_taker) * $price_2_in_ref;  // fees
								   
	}
	
	// 6. now comes the decision what to do
    if (  ($new_portfolio_value_ref_sell <= $cur_portfolio_value_ref) && ($new_portfolio_value_ref_buy <= $cur_portfolio_value_ref) ) {
			// we do nothing here!!
			echo "no existing order is appealing to us...";
	} else {
			if ($new_portfolio_value_ref_buy>$new_portfolio_value_ref_sell) {
					// we do buy
					echo "We do buy $tradable_amount_1 $currency_1\n";
					echo "Portfolio value should go to $new_portfolio_value_ref_buy $currency_ref\n";
					$api->buy($curpair_1_2, $bestask, $tradable_amount_1);
			} else {
					// we do sell
					echo "We do sell $tradable_amount_1 $currency_1\n";
					echo "Portfolio value should go to $new_portfolio_value_ref_sell $currency_ref\n";
					$api->sell($curpair_1_2, $bestbid, $tradable_amount_1);
			}	
			
	}
	*/
	echo "Bot iteration over... \n\n";

?>
