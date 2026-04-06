import { NextResponse } from 'next/server';
import crypto from 'crypto';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { orderId, amount } = body;

    if (!orderId || !amount) {
      return NextResponse.json(
        { error: 'Missing orderId or amount' },
        { status: 400 }
      );
    }

    const merchantId = process.env.PAYHERE_MERCHANT_ID;
    const merchantSecret = process.env.PAYHERE_SECRET;

    if (!merchantId || !merchantSecret) {
      console.error('PAYHERE_MERCHANT_ID or PAYHERE_SECRET environment variables are missing');
      return NextResponse.json(
        { error: 'Internal server error: payment configuration missing' },
        { status: 500 }
      );
    }

    const currency = 'LKR';
    
    // PayHere requires standard decimal formatting for amount.
    // For Sri Lanka Rupees (LKR) it typically requires 2 decimal places.
    const formattedAmount = Number(amount).toFixed(2);

    const hashedSecret = crypto
      .createHash('md5')
      .update(merchantSecret)
      .digest('hex')
      .toUpperCase();

    const hashString = `${merchantId}${orderId}${formattedAmount}${currency}${hashedSecret}`;
    
    const hash = crypto
      .createHash('md5')
      .update(hashString)
      .digest('hex')
      .toUpperCase();

    return NextResponse.json({ hash });
  } catch (error) {
    console.error('Error generating PayHere hash:', error);
    return NextResponse.json(
      { error: 'Failed to generate hash' },
      { status: 500 }
    );
  }
}
