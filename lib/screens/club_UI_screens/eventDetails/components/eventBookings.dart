import 'dart:convert';
import 'dart:io';

import 'package:bookario/components/loading.dart';
import 'package:bookario/components/networking.dart';
import 'package:bookario/components/rich_text_row.dart';
import 'package:bookario/components/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class EventBookings extends StatefulWidget {
  final event;

  const EventBookings({Key key, @required this.event}) : super(key: key);
  @override
  _EventBookingsState createState() => _EventBookingsState();
}

class _EventBookingsState extends State<EventBookings> {
  List<bool> isExpanded = new List();
  List<dynamic> bookingData = [];
  List bookingDetails = [], moreBookingDetails = [];
  int limit, offset;
  bool hasBookings = false,
      screenLoading = true,
      loadMore = false,
      loadingMore = false,
      showQRScanner = false,
      qrDataFetched = false,
      ticketBooked = false;
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrAPIRequestData, qrAPIRequestBookingDetails;

  @override
  void initState() {
    offset = 0;
    limit = 10;
    getBookingData();
    super.initState();
  }

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   if (Platform.isAndroid) {
  //     controller.pauseCamera();
  //   } else if (Platform.isIOS) {
  //     controller.resumeCamera();
  //   }
  // }

  getBookingData() async {
    try {
      var response = await Networking.getData('bookings/get-event-bookings', {
        "eventId": widget.event['eventId'].toString(),
        "limit": limit.toString(),
        "offset": offset.toString(),
      });
      if (response['data'].length > 0) {
        setState(() {
          for (int i = 0; i < response['data'].length; i++) {
            isExpanded.add(false);
            bookingDetails.length = i + 1;
            bookingDetails[i] =
                json.decode(response['data'][i]['bookingDetails']);
          }
          hasBookings = true;
          loadMore = true;
          loadingMore = false;
          bookingData += response['data'];
        });
      } else {
        setState(() {
          screenLoading = false;
          loadMore = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea =
        (SizeConfig.screenWidth < 400 || SizeConfig.screenHeight < 400)
            ? 150.0
            : 300.0;
    return Container(
      height: scanArea + 100,
      child: QRView(
        key: qrKey,
        cameraFacing: CameraFacing.front,
        onQRViewCreated: _onQRViewCreated,
        formatsAllowed: [BarcodeFormat.qrcode],
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea,
        ),
      ),
    );
  }

  _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      checkQR();
    });
  }

  void checkQR() async {
    showQRScanner = false;
    try {
      var response = await Networking.getData('bookings/get-booking-by-code', {
        "passCode": result.code,
      });
      if (response['success']) {
        setState(() {
          qrAPIRequestData = response['data'][0];
          qrDataFetched = true;
          ticketBooked = true;
          qrAPIRequestBookingDetails =
              json.decode(qrAPIRequestData['bookingDetails']);
        });
      } else {
        setState(() {
          qrDataFetched = true;
          ticketBooked = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Event Bookings"),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                qrDataFetched = false;
                showQRScanner = !showQRScanner;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(50)),
              padding: EdgeInsets.only(right: 15, left: 15),
              child: SvgPicture.asset(
                'assets/icons/qr-code.svg',
                height: getProportionateScreenWidth(18),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: getProportionateScreenHeight(5)),
              showQRScanner ? _buildQrView(context) : Container(),
              qrDataFetched
                  ? ticketBooked
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Pass booked!',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 20),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 40),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Stack(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ...List.generate(
                                                    qrAPIRequestBookingDetails
                                                        .length, (j) {
                                                  return Container(
                                                    margin: EdgeInsets.only(
                                                        bottom: 8),
                                                    child: Column(
                                                      children: [
                                                        qrAPIRequestBookingDetails[
                                                                        j][
                                                                    'passCategory'] !=
                                                                'Couples'
                                                            ? Row(
                                                                children: [
                                                                  Text(
                                                                    qrAPIRequestBookingDetails[
                                                                            j][
                                                                        'name'],
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline6
                                                                        .copyWith(
                                                                          fontSize:
                                                                              getProportionateScreenWidth(16),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                  ),
                                                                  Text(
                                                                    ', ' +
                                                                        qrAPIRequestBookingDetails[j]
                                                                            [
                                                                            'gender'],
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline6
                                                                        .copyWith(
                                                                          fontSize:
                                                                              getProportionateScreenWidth(13),
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                  ),
                                                                  Text(
                                                                    ', ' +
                                                                        qrAPIRequestBookingDetails[j]
                                                                            [
                                                                            'age'],
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline6
                                                                        .copyWith(
                                                                          fontSize:
                                                                              getProportionateScreenWidth(13),
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                  ),
                                                                ],
                                                              )
                                                            : Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        qrAPIRequestBookingDetails[j]
                                                                            [
                                                                            'maleName'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(16),
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        ', ' +
                                                                            qrAPIRequestBookingDetails[j]['maleGender'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        ', ' +
                                                                            qrAPIRequestBookingDetails[j]['maleAge'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        qrAPIRequestBookingDetails[j]
                                                                            [
                                                                            'femaleName'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(16),
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        ', ' +
                                                                            qrAPIRequestBookingDetails[j]['femaleGender'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        ', ' +
                                                                            qrAPIRequestBookingDetails[j]['femaleAge'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              qrAPIRequestBookingDetails[
                                                                      j][
                                                                  'passCategory'],
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .copyWith(
                                                                    fontSize:
                                                                        getProportionateScreenWidth(
                                                                            13),
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                            ),
                                                            Text(
                                                              ', ' +
                                                                  qrAPIRequestBookingDetails[
                                                                          j][
                                                                      'passType'],
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .copyWith(
                                                                    fontSize:
                                                                        getProportionateScreenWidth(
                                                                            13),
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                                SizedBox(height: 10),
                                                RichTextRow(
                                                  textLeft: "Booked on:  ",
                                                  textRight:
                                                      qrAPIRequestData['date'],
                                                ),
                                                RichTextRow(
                                                  textLeft: "Paid:  ₹",
                                                  textRight: qrAPIRequestData[
                                                          'bookingAmount']
                                                      .toString(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Pass not found!',
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          ),
                        )
                  : Container(),
              SizedBox(height: getProportionateScreenHeight(5)),
              hasBookings
                  ? Column(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(
                                bookingData.length,
                                (index) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 6),
                                    child: Container(
                                      child: AnimatedCrossFade(
                                        crossFadeState: isExpanded[index]
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration: Duration(milliseconds: 200),
                                        firstChild: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: Stack(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 12,
                                                          vertical: 5),
                                                      color: Colors.grey[300],
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          RichText(
                                                            text: bookingDetails[
                                                                            index][0]
                                                                        [
                                                                        'passCategory'] !=
                                                                    'Couples'
                                                                ? TextSpan(
                                                                    text: 'Booked by: ' +
                                                                        bookingData[index]
                                                                            [
                                                                            'name'],
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline6
                                                                        .copyWith(
                                                                          fontSize:
                                                                              getProportionateScreenWidth(17),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                  )
                                                                : TextSpan(
                                                                    text: 'Booked by: ' +
                                                                        bookingDetails[index][0]
                                                                            [
                                                                            'maleName'],
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline6
                                                                        .copyWith(
                                                                          fontSize:
                                                                              getProportionateScreenWidth(17),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                  ),
                                                          ),
                                                          RichTextRow(
                                                            textLeft:
                                                                "Booked on:  ",
                                                            textRight:
                                                                bookingData[
                                                                        index]
                                                                    ['date'],
                                                          ),
                                                          RichTextRow(
                                                            textLeft: "Paid:  ",
                                                            textRight: bookingData[
                                                                        index][
                                                                    'bookingAmount']
                                                                .toString(),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isExpanded[index]
                                                          ? isExpanded[index] =
                                                              false
                                                          : isExpanded[index] =
                                                              true;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5.0),
                                                    child: Icon(
                                                      isExpanded[index]
                                                          ? Icons.arrow_drop_up
                                                          : Icons
                                                              .arrow_drop_down,
                                                      size: 30,
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        secondChild: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: Stack(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 12,
                                                          vertical: 5),
                                                      color: Colors.grey[300],
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          ...List.generate(
                                                              bookingDetails[
                                                                      index]
                                                                  .length, (j) {
                                                            return Container(
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          8),
                                                              child: Column(
                                                                children: [
                                                                  bookingDetails[index][j]
                                                                              [
                                                                              'passCategory'] !=
                                                                          'Couples'
                                                                      ? Row(
                                                                          children: [
                                                                            Text(
                                                                              bookingDetails[index][j]['name'],
                                                                              style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                    fontSize: getProportionateScreenWidth(16),
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.black,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              ', ' + bookingDetails[index][j]['gender'],
                                                                              style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                    fontSize: getProportionateScreenWidth(13),
                                                                                    color: Colors.black,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              ', ' + bookingDetails[index][j]['age'],
                                                                              style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                    fontSize: getProportionateScreenWidth(13),
                                                                                    color: Colors.black,
                                                                                  ),
                                                                            ),
                                                                          ],
                                                                        )
                                                                      : Column(
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                Text(
                                                                                  bookingDetails[index][j]['maleName'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(16),
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  ', ' + bookingDetails[index][j]['maleGender'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(13),
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  ', ' + bookingDetails[index][j]['maleAge'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(13),
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                Text(
                                                                                  bookingDetails[index][j]['femaleName'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(16),
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  ', ' + bookingDetails[index][j]['femaleGender'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(13),
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                                Text(
                                                                                  ', ' + bookingDetails[index][j]['femaleAge'],
                                                                                  style: Theme.of(context).textTheme.headline6.copyWith(
                                                                                        fontSize: getProportionateScreenWidth(13),
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        bookingDetails[index][j]
                                                                            [
                                                                            'passCategory'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                      Text(
                                                                        ', ' +
                                                                            bookingDetails[index][j]['passType'],
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline6
                                                                            .copyWith(
                                                                              fontSize: getProportionateScreenWidth(13),
                                                                              color: Colors.black,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }),
                                                          SizedBox(height: 10),
                                                          RichTextRow(
                                                            textLeft:
                                                                "Booked on:  ",
                                                            textRight:
                                                                bookingData[
                                                                        index]
                                                                    ['date'],
                                                          ),
                                                          RichTextRow(
                                                            textLeft:
                                                                "Paid:  ₹",
                                                            textRight: bookingData[
                                                                        index][
                                                                    'bookingAmount']
                                                                .toString(),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isExpanded[index]
                                                          ? isExpanded[index] =
                                                              false
                                                          : isExpanded[index] =
                                                              true;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5.0),
                                                    child: Icon(
                                                      isExpanded[index]
                                                          ? Icons.arrow_drop_up
                                                          : Icons
                                                              .arrow_drop_down,
                                                      size: 30,
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: getProportionateScreenWidth(20)),
                            ],
                          ),
                        ),
                        loadMore
                            ? loadingMore
                                ? Loading()
                                : FlatButton(
                                    onPressed: () {
                                      setState(() {
                                        offset += limit;
                                        loadingMore = true;
                                      });
                                      getBookingData();
                                    },
                                    child: Text(
                                      'load more',
                                    ),
                                    splashColor:
                                        Theme.of(context).primaryColorLight,
                                  )
                            : Container(),
                      ],
                    )
                  : screenLoading
                      ? Loading()
                      : Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Bookings will be available here\nwhen customers starts buying passes.',
                            textAlign: TextAlign.center,
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
