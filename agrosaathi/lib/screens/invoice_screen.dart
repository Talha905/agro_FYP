import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bid_model.dart';
import '../models/listing_model.dart';
import '../services/firestore_refs.dart';

class InvoiceScreen extends StatefulWidget {
  final BidModel bid;
  final ListingModel listing;

  const InvoiceScreen({super.key, required this.bid, required this.listing});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  String farmerName = 'Loading...';
  String buyerName = 'Loading...';
  bool isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    try {
      final farmerDoc = await FirestoreRefs.users.doc(widget.listing.farmerId).get();
      final buyerDoc = await FirestoreRefs.users.doc(widget.bid.buyerId).get();
      
      if (mounted) {
        setState(() {
          farmerName = (farmerDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Farmer';
          buyerName = (buyerDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Buyer';
        });
      }
    } catch (e) {
      if (mounted) setState(() => farmerName = buyerName = 'Error loading names');
    }
  }

  Future<void> _generatePdf() async {
    setState(() => isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      final double totalAmount = widget.bid.bidAmountPerUnit * widget.bid.quantity;
      final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          pw.SizedBox(height: 8),
                          pw.Text('AgroSaathi Marketplace', style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.green800, width: 2),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Text('PAID', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  _buildPdfDetailRow('Transaction ID', widget.bid.id ?? 'N/A'),
                  pw.SizedBox(height: 12),
                  _buildPdfDetailRow('Date Paid', dateFormat.format(DateTime.now())),
                  pw.SizedBox(height: 12),
                  _buildPdfDetailRow('Status', 'Successful'),
                  pw.Divider(height: 40),
                  pw.Text('Party Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Farmer Name', farmerName),
                  pw.SizedBox(height: 12),
                  _buildPdfDetailRow('Buyer Name', buyerName),
                  pw.Divider(height: 40),
                  pw.Text('Item Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  _buildPdfDetailRow('Crop Name', widget.listing.cropName),
                  pw.SizedBox(height: 12),
                  _buildPdfDetailRow('Unit Price', 'Rs. ${widget.bid.bidAmountPerUnit} per ${widget.listing.unit}'),
                  pw.SizedBox(height: 12),
                  _buildPdfDetailRow('Quantity', '${widget.bid.quantity} ${widget.listing.unit}'),
                  pw.Divider(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Amount Paid', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs. $totalAmount', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                  pw.SizedBox(height: 60),
                  pw.Center(
                    child: pw.Text('Thank you for trading on AgroSaathi.', style: const pw.TextStyle(color: PdfColors.grey600)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'AgroSaathi_Invoice_${widget.bid.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => isGeneratingPdf = false);
    }
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14)),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14), textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.bid.bidAmountPerUnit * widget.bid.quantity;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Invoice', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: isGeneratingPdf 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.picture_as_pdf),
            onPressed: isGeneratingPdf ? null : _generatePdf,
            tooltip: 'Download PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.agriculture, color: Colors.green[800], size: 28),
                            const SizedBox(width: 8),
                            Text('INVOICE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green[800], letterSpacing: 2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('AgroSaathi Marketplace', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[800]!, width: 2),
                      ),
                      child: Text('PAID', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction details
                    _buildDetailRow('Transaction ID', widget.bid.id ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Date Paid', dateFormat.format(DateTime.now())), // Ideally use payment timestamp
                    const SizedBox(height: 12),
                    _buildDetailRow('Status', 'Successful'),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // Party Details
                    Text('Party Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    _buildDetailRow('Farmer', farmerName),
                    const SizedBox(height: 12),
                    _buildDetailRow('Buyer', buyerName),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // Crop details
                    Text('Item Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    _buildDetailRow('Crop Name', widget.listing.cropName),
                    const SizedBox(height: 12),
                    _buildDetailRow('Unit Price', '₹${widget.bid.bidAmountPerUnit} per ${widget.listing.unit}'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Quantity', '${widget.bid.quantity} ${widget.listing.unit}'),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Text('Total Amount Paid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                        Text('₹$totalAmount', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blue[800])),
                      ],
                    ),

                    const SizedBox(height: 40),
                    
                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.verified_user, color: Colors.green[600], size: 40),
                          const SizedBox(height: 12),
                          Text('Thank you for trading on AgroSaathi.', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
