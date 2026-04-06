import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { db } from '../../../../lib/firebaseAdmin';

export async function POST(request: Request) {
  try {
    // PayHere sends webhook data as URL-encoded form data
    const formData = await request.formData();
    
    const merchant_id = formData.get('merchant_id') as string;
    const order_id = formData.get('order_id') as string;
    const payhere_amount = formData.get('payhere_amount') as string;
    const payhere_currency = formData.get('payhere_currency') as string;
    const status_code = formData.get('status_code') as string;
    const md5sig = formData.get('md5sig') as string;

    const merchantSecret = process.env.PAYHERE_SECRET;

    if (!merchantSecret) {
      console.error('PAYHERE_SECRET environment variable is missing');
      return NextResponse.json({ error: 'Server configuration error' }, { status: 500 });
    }

    // Verify md5sig
    // Formula: uppercase(MD5(merchant_id + order_id + payhere_amount + payhere_currency + status_code + uppercase(MD5(merchant_secret))))
    const hashedSecret = crypto
      .createHash('md5')
      .update(merchantSecret)
      .digest('hex')
      .toUpperCase();

    const localHashString = `${merchant_id}${order_id}${payhere_amount}${payhere_currency}${status_code}${hashedSecret}`;
    
    const localMd5sig = crypto
      .createHash('md5')
      .update(localHashString)
      .digest('hex')
      .toUpperCase();

    if (localMd5sig !== md5sig) {
      console.error(`Invalid PayHere signature for order ${order_id}`);
      return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
    }

    // Status Code 2 means success
    if (status_code === '2') {
      try {
        await db.collection('parcels').doc(order_id).update({
          paymentStatus: 'paid'
        });
        console.log(`Successfully updated payment status for parcel: ${order_id}`);
      } catch (dbError) {
        console.error(`Failed to update Firestore for parcel ${order_id}:`, dbError);
        // We still return 200 so PayHere stops retrying, but log the error
        return new NextResponse('Database Error', { status: 200 }); 
      }
    } else {
      console.log(`Payment not successful for order ${order_id}. Status: ${status_code}`);
    }

    // PayHere expects a 200 OK response unconditionally if the request is structurally valid and the signature matches
    return new NextResponse('OK', { status: 200 });
  } catch (error) {
    console.error('Error handling PayHere webhook:', error);
    return new NextResponse('Failed Delivery', { status: 500 });
  }
}
