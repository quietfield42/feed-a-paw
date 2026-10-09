import '/app_state.dart';
import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show apawIconChips, apawPaper, apawPrimary, apawText, apawThemed, ApawColors;

/// Logging a pickup from a butcher, on the region's paper.
///
/// A driver with no round under way is told so, rather than filling the form
/// in and finding it cannot save: a collection belongs to a run, and without
/// one the database has nothing to attach it to.
class FeedPickupForm extends StatefulWidget {
  const FeedPickupForm({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedPickupForm> createState() => _FeedPickupFormState();
}

class _FeedPickupFormState extends State<FeedPickupForm> {
  final _butcher = TextEditingController();
  final _kilos = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String _error = '';

  /// The butchers already known, and which one this pickup came from.
  ///
  /// `feed_collections` has had a `butcher_id` since the first migration and
  /// every pickup left it null, because the form only ever asked for a typed
  /// name. So `feed_butchers` stayed empty, "Hassan", "hassan butcher" and
  /// "Hassan's" became three different suppliers, and nobody could answer the
  /// one question worth asking of a donated-meat operation: how much does each
  /// butcher actually give us.
  ///
  /// `butcher_name` is still written alongside the id, because it is a
  /// snapshot — a butcher who is later renamed should not rewrite what last
  /// winter's pickups say.
  List<Map<String, dynamic>> _butchers = [];
  String _butcherId = '';
  bool _newOne = false;

  static const _kNew = '__new__';

  @override
  void initState() {
    super.initState();
    _loadButchers();
  }

  Future<void> _loadButchers() async {
    try {
      final got = await SupaFlow.client
          .from('feed_butchers')
          .select('id, name')
          .eq('active', true)
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _butchers = [for (final r in got) Map<String, dynamic>.from(r)];
          // Nobody on the list yet means the only sensible thing is to type
          // one, so do not make somebody tap "Somebody new" first.
          _newOne = _butchers.isEmpty;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _newOne = true);
    }
  }

  @override
  void dispose() {
    _butcher.dispose();
    _kilos.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final run = FFAppState().currentRunId;
    if (run.isEmpty) {
      setState(() => _error = 'Start the round first, on the driver screen.');
      return;
    }
    final typed = _butcher.text.trim();
    if (_butcherId.isEmpty && typed.isEmpty) {
      setState(() => _error = 'Which butcher was it?');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      // A butcher nobody has logged before is added to the list, so the next
      // pickup can simply be tapped rather than typed again — and so the two
      // spellings never become two suppliers.
      var id = _butcherId;
      var name = typed;
      if (id.isEmpty) {
        final made = await SupaFlow.client
            .from('feed_butchers')
            .insert({'name': typed})
            .select('id, name')
            .single();
        id = (made['id'] ?? '').toString();
        name = (made['name'] ?? typed).toString();
      } else {
        name = _butchers
            .firstWhere((b) => b['id'].toString() == id,
                orElse: () => <String, dynamic>{'name': typed})['name']
            .toString();
      }

      await SupaFlow.client.from('feed_collections').insert({
        'run_id': run,
        if (id.isNotEmpty) 'butcher_id': id,
        'butcher_name': name,
        'kilos': num.tryParse(_kilos.text.trim()) ?? 0,
        'collected_by': SupaFlow.client.auth.currentUser?.id,
        'note': _note.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pickup logged.')));
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That did not save. Try again in a moment.');
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ApawColors.sand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ApawColors.sand),
        ),
      );

  @override
  Widget build(BuildContext context) => apawThemed(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          apawPaper(
            title: 'Where it came from',
            icon: 'feed-role-supplier',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_butchers.isNotEmpty)
                    apawIconChips<String>(
                      {
                        for (final b in _butchers)
                          b['id'].toString(): (
                            (b['name'] ?? '').toString(),
                            'feed-role-supplier' as Object?
                          ),
                        _kNew: ('Somebody new', 'feed-pickup-kilos' as Object?),
                      },
                      _newOne ? _kNew : _butcherId,
                      (v) => setState(() {
                        _newOne = v == _kNew;
                        _butcherId = _newOne ? '' : v;
                        if (!_newOne) _butcher.clear();
                      }),
                    ),
                  if (_newOne) ...[
                    if (_butchers.isNotEmpty) const SizedBox(height: 10),
                    TextField(
                        controller: _butcher,
                        decoration: _field('Which butcher')),
                  ],
                ],
              ),
            ),
          ),
          apawPaper(
            title: 'How much',
            icon: 'feed-pickup-kilos',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _kilos,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _field('Kilos'),
              ),
            ),
          ),
          apawPaper(
            title: 'Anything worth saying',
            icon: 'feed-stop-note',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                  controller: _note, maxLines: 3, decoration: _field('Note')),
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error,
                  textAlign: TextAlign.center,
                  style: apawText(size: 13.5, color: ApawColors.lost)),
            ),
          apawPrimary(_saving ? 'Saving…' : 'Save the pickup',
              _saving ? null : _save,
              busy: _saving, icon: 'feed-pickup-parcel'),
          const SizedBox(height: 10),
        ],
      ));
}
