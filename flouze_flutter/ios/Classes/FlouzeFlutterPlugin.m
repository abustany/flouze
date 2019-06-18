#import "FlouzeFlutterPlugin.h"

#import "flouze_flutter_ios.h"

@implementation FlouzeFlutterPlugin {
  FlutterEventSink _eventSink;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flouze_flutter"
            binaryMessenger:[registrar messenger]];
  FlutterEventChannel *events = [FlutterEventChannel
      eventChannelWithName:@"flouze_flutter/events"
            binaryMessenger:[registrar messenger]];
  FlouzeFlutterPlugin* instance = [[FlouzeFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [events setStreamHandler:instance];

}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  dispatch_queue_t global_queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
  __weak typeof(self) weakSelf = self;

  dispatch_async(global_queue, ^{
    [weakSelf handleMethodCallHelper:call result:result];
  });
}

static void* getPointer(NSDictionary* arguments, NSString* name) {
  NSNumber *ptr = [arguments objectForKey:name];
  return (void*)[ptr longValue];
}

static void returnByteArray(FlutterResult result, uint8_t *data, size_t data_len) {
  result([FlutterStandardTypedData
          typedDataWithBytes:[NSData
                              dataWithBytesNoCopy:data
                              length:data_len
                              freeWhenDone:true]]);
}

- (void)accountListChanged {
  if (_eventSink) {
    _eventSink(@"account_list_changed");
  }
}

- (void)handleMethodCallHelper:(FlutterMethodCall *)call result:(FlutterResult)result {
  char *error = nil;

  if ([@"init" isEqualToString:call.method]) {
    result(nil);
  } else if ([@"SledRepository::temporary" isEqualToString:call.method]) {
    void *repo = flouze_sled_repository_temporary(&error);

    if (!error) {
      result([NSNumber numberWithLong:(long)repo]);
    }
  } else if ([@"SledRepository::fromFile" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    NSString *path = [arguments objectForKey:@"path"];
    void *repo = flouze_sled_repository_from_file([path UTF8String], &error);

    if (!error) {
      result([NSNumber numberWithLong:(long)repo]);
    }
  } else if ([@"SledRepository::close" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");

    flouze_sled_repository_destroy(repo);

    result(nil);
  } else if ([@"SledRepository::addAccount" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountData = [arguments objectForKey:@"account"];

    flouze_sled_repository_add_account(repo, [[accountData data] bytes], (size_t)[[accountData data] length], &error);

    if (!error) {
      [self accountListChanged];
      result(nil);
    }
  } else if ([@"SledRepository::listAccounts" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    uint8_t *account_list = NULL;
    size_t account_list_len = 0;

    flouze_sled_repository_list_accounts(repo, &account_list, &account_list_len, &error);

    if (!error) {
      returnByteArray(result, account_list, account_list_len);
    }
  } else if ([@"SledRepository::listTransactions" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];
    uint8_t *tx_list = NULL;
    size_t tx_list_len = 0;

    flouze_sled_repository_list_transactions(repo, [[accountId data] bytes], [[accountId data] length], &tx_list, &tx_list_len, &error);

    if (!error) {
      returnByteArray(result, tx_list, tx_list_len);
    }
  } else if ([@"SledRepository::addTransaction" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];
    FlutterStandardTypedData *tx = [arguments objectForKey:@"transaction"];

    flouze_sled_repository_add_transaction(repo, [[accountId data] bytes], (size_t)[[accountId data] length], [[tx data] bytes], (size_t)[[tx data] length], &error);

    if (!error) {
      result(nil);
    }
  } else if ([@"Repository::getBalance" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];
    uint8_t *balance = NULL;
    size_t balance_len = 0;

    flouze_sled_repository_get_balance(repo, [[accountId data] bytes], [[accountId data] length], &balance, &balance_len, &error);

    if (!error) {
      returnByteArray(result, balance, balance_len);
    }
  } else if ([@"JsonRpcClient::create" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    NSString *url = [arguments objectForKey:@"url"];
    void *client = flouze_json_rpc_client_create([url UTF8String], &error);

    if (!error) {
      result([NSNumber numberWithLong:(long)client]);
    }
  } else if ([@"JsonRpcClient::createAccount" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountData = [arguments objectForKey:@"account"];

    flouze_json_rpc_client_create_account(repo, [[accountData data] bytes], (size_t)[[accountData data] length], &error);

    if (!error) {
      result(nil);
    }
  } else if ([@"JsonRpcClient::getAccountInfo" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *client = getPointer(arguments, @"ptr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];
    uint8_t *account = NULL;
    size_t account_len = 0;

    flouze_json_rpc_client_get_account_info(client, [[accountId data] bytes], [[accountId data] length], &account, &account_len, &error);

    if (!error) {
      returnByteArray(result, account, account_len);
    }
  } else if ([@"Sync::cloneRemote" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"repoPtr");
    void *remote = getPointer(arguments, @"remotePtr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];

    flouze_sync_clone_remote(repo, remote, [[accountId data] bytes], (size_t)[[accountId data] length], &error);

    if (!error) {
      [self accountListChanged];
      result(nil);
    }
  } else if ([@"Sync::sync" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    void *repo = getPointer(arguments, @"repoPtr");
    void *remote = getPointer(arguments, @"remotePtr");
    FlutterStandardTypedData *accountId = [arguments objectForKey:@"accountId"];

    flouze_sync_sync(repo, remote, [[accountId data] bytes], (size_t)[[accountId data] length], &error);

    if (!error) {
      result(nil);
    }
  } else {
    result(FlutterMethodNotImplemented);
    return;
  }

  if (error != NULL) {
    result([FlutterError errorWithCode:@"FlouzeError" message:[NSString stringWithUTF8String:error] details:nil]);
    flouze_error_free(error);
  }
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)eventSink {
  _eventSink = eventSink;
  return nil;
}

@end
