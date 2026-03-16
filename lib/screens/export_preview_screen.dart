import 'dart:io';

import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportPreviewScreen extends StatefulWidget {
  const ExportPreviewScreen({
    super.key,
    this.exportedFile,
    this.excelCompatible = false,
  });

  final File? exportedFile;
  final bool excelCompatible;

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  late final Future<List<TransactionRecord>> _transactionsFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = RepositoryRegistry.expenseRepository
        .getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.exportPreviewTitle),
        actions: [
          if (widget.exportedFile != null)
            IconButton(
              onPressed: _copyPullCommand,
              tooltip: strings.copyPullCommandLabel,
              icon: const Icon(Icons.terminal_rounded),
            ),
          if (widget.exportedFile != null)
            IconButton(
              onPressed: _isDownloading ? null : _downloadFile,
              tooltip: strings.downloadLabel,
              icon: _isDownloading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
            ),
        ],
      ),
      body: FutureBuilder<List<TransactionRecord>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.exportFailure(snapshot.error.toString())),
              ),
            );
          }

          final transactions = snapshot.data ?? const [];
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.exportPreviewEmpty),
              ),
            );
          }

          final rows = transactions
              .map(
                (transaction) => <String>[
                  transaction.id,
                  transaction.title,
                  transaction.amount.toStringAsFixed(0),
                  transaction.date.toIso8601String(),
                  transaction.category,
                  transaction.type.name,
                  transaction.note ?? '',
                ],
              )
              .toList(growable: false);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.excelCompatible
                          ? strings.exportExcelLabel
                          : strings.exportCsvLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.exportPreviewSubtitle(rows.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.exportedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${strings.latestExportLabel} ${widget.exportedFile!.path}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primaryContainer,
                          ),
                          columns: [
                            DataColumn(label: Text(strings.exportColumnId)),
                            DataColumn(label: Text(strings.exportColumnTitle)),
                            DataColumn(label: Text(strings.exportColumnAmount)),
                            DataColumn(label: Text(strings.exportColumnDate)),
                            DataColumn(
                              label: Text(strings.exportColumnCategory),
                            ),
                            DataColumn(label: Text(strings.exportColumnType)),
                            DataColumn(label: Text(strings.exportColumnNote)),
                          ],
                          rows: rows
                              .map(
                                (row) => DataRow(
                                  cells: row
                                      .map((cell) => DataCell(Text(cell)))
                                      .toList(growable: false),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyPullCommand() async {
    final source = widget.exportedFile;
    if (source == null) {
      return;
    }

    final strings = AppStrings.of(context);
    final remotePath = source.path.replaceAll('\\', '/');
    final command = 'adb -s emulator-5554 pull "$remotePath" .';

    await Clipboard.setData(ClipboardData(text: command));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.pullCommandCopiedSuccess)));
  }

  Future<void> _downloadFile() async {
    final source = widget.exportedFile;
    if (source == null) {
      return;
    }

    final strings = AppStrings.of(context);
    setState(() {
      _isDownloading = true;
    });

    try {
      Directory targetDirectory;
      if (Platform.isAndroid) {
        targetDirectory = Directory('/storage/emulated/0/Download');
      } else {
        targetDirectory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }
      await targetDirectory.create(recursive: true);

      final filename = source.uri.pathSegments.isNotEmpty
          ? source.uri.pathSegments.last
          : 'export.csv';
      var destination = File(
        '${targetDirectory.path}${Platform.pathSeparator}$filename',
      );

      if (await destination.exists()) {
        final dot = filename.lastIndexOf('.');
        final base = dot > 0 ? filename.substring(0, dot) : filename;
        final ext = dot > 0 ? filename.substring(dot) : '';
        destination = File(
          '${targetDirectory.path}${Platform.pathSeparator}${base}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
      }

      final saved = await source.copy(destination.path);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.downloadSaved(saved.path))),
      );

      await _openAfterDownload(saved, targetDirectory);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.downloadFailed(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _openAfterDownload(File savedFile, Directory directory) async {
    final strings = AppStrings.of(context);
    try {
      final result = Platform.isAndroid
          ? await OpenFilex.open(savedFile.path)
          : await OpenFilex.open(directory.path);
      if (!mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        final details = result.message.trim();
        final suffix = details.isEmpty ? '' : ' $details';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.openFileFailed}$suffix')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.openFileFailed} ${error.toString()}'),
        ),
      );
    }
  }
}
