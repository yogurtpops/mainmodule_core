package src.com;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class DownloaderService extends src.com.google.android.vending.expansion.downloader.impl.DownloaderService {
    public static final String BASE64_PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo3G+fMO66c/B/ullYkGbcRPPXnTe6UIwOo/f08JuVHZ3e6UDhDtxZq1/D03Wy4T12exZ+a1p1pwgNa2JjC/h5xvSu7uYrpZ9ceaJB0Ni8kTf7K09uuXbik8V6wABKPjHozfPKokipi1yeW3CCw4VhETKbSXy65M5rqWwu8h28dyleAWDAYOrI5Q2RxK+FB+uVdbBlcgjkexTvB7t4ftlhBFbKT8aiAkqTEOJ2L5T1ixo9iYdPI7fThmCSFJ0YaoNRBTgNTaC2xCYis98DmEwScsXSOaz1UkfzK084CGp3eoGSJg/RT0PUf8ExdsIHPqf43fQNqKvgy18RTElwlzB3QIDAQAB"; // TODO Add public key
    private static final byte[] SALT = new byte[]{1, 4, -1, -1, 14, 42, -79, -21, 13, 2, -8, -11, 62, 1, -10, -101, -19, 41, -12, 18};
    // TODO Replace with random numbers of your choice
    @Override public String getPublicKey() {
        return BASE64_PUBLIC_KEY;
    }
    @Override public byte[] getSALT() {
        return SALT;
    }
    @Override public String getAlarmReceiverClassName() {
        return DownloaderServiceBroadcastReceiver.class.getName();
    }
}