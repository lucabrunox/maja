namespace Dova {
	public class ArrayList<T> : Dova.ListModel<T> {
		public ArrayList (Dova.List<T>? list = null) {
			if (list != null) {
				foreach (var elem in list) {
					append (elem);
				}
			}
		}
		public extern override void append (T element);
		public override void clear () {
			((dynamic Object) this).splice (0, length);
		}
		public override bool contains (T element) {
			foreach (var elem in this) {
				if (elem == element) {
					return true;
				}
			}
			return false;
		}
		public extern override T get (int index);
		public extern override Dova.Iterator<T> iterator ();
		public override bool remove (T element) {
			for (var i=0; i < length; i++) {
				if (this[i] == element) {
					((dynamic Object) this).splice (i, 1);
					return true;
				}
			}
			return false;
		}
		public extern override void set (int index, T element);
		public extern override int length { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class DequeModel<T> : Dova.Object {
		public DequeModel ();
		public abstract T pop_head ();
		public abstract T pop_tail ();
		public abstract void push_head (T element);
		public abstract void push_tail (T element);
	}
	[CCode (cheader_filename = "dova-model.h")]
	public class HashMap<K,V> : Dova.MapModel<K,V> {
		public HashMap ();
		public extern bool contains_key (K key);
		public extern override V get (K key);
		public extern void remove (K key);
		public extern override void set (K key, V value);
		public Dova.Iterable<K> keys { get; private set; }
		public extern int size { get; private set; }
		public Dova.Iterable<V> values { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public class HashSet<T> : Dova.SetModel<T> {
		public HashSet ();
		public override bool add (T element) {
			if (element in this) {
				return false;
			}
			((dynamic HashMap<T,bool>) this)[element] = true;
			return true;
		}
		public extern override void clear ();
		public extern override bool contains (T element);
		public extern override Dova.Iterator<T> iterator ();
		public extern override bool remove (T element);
		public extern override int size { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class IntegerModel : Dova.Object {
		public IntegerModel ();
		public abstract int get ();
		public abstract void set (int value);
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class Iterable<T> : Dova.Object {
		public Iterable ();
		/*public bool all (FilterFunc<T> func);
		public bool any (FilterFunc<T> func);
		public Dova.Iterable<T> drop (int n);
		public Dova.Iterable<T> filter (FilterFunc<T> func);*/
		public virtual Dova.Iterator<T> iterator () {
			if (this is Javascript.Array) {
				return ((ListModel<T>) this).iterator ();
			} else if (this is Javascript.Object) {
				return ((SetModel<T>) this).iterator ();
			} else {
				assert_not_reached ();
			}
		}
		/*public Dova.Iterable<R> map<R> (MapFunc<T,R> func);
		public Dova.Iterable<T> take (int n);
		public Dova.List<T> to_list ();*/
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class ListModel<T> : Dova.Iterable<T> {
		protected ListModel ();
		public abstract void append (T element);
		public abstract void clear ();
		public abstract bool contains (T element);
		public abstract T get (int index);
		public abstract bool remove (T element);
		public abstract void set (int index, T element);
		public new Dova.Iterator<T> iterator () {
			return null;
		}
		public abstract int length { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class MapModel<K,V> : Dova.Object {
		public MapModel ();
		public abstract V get (K key);
		public abstract void set (K key, V value);
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class SetModel<T> : Dova.Iterable<T> {
		protected SetModel ();
		public abstract bool add (T element);
		public abstract void clear ();
		public abstract bool contains (T element);
		public abstract bool remove (T element);
		public new Dova.Iterator<T> iterator () {
			return null;
		}
		public abstract int size { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public delegate int CompareFunc<T> (T a, T b);
}
[CCode (cheader_filename = "dova-model.h")]
public delegate bool FilterFunc<T> (T element);
[CCode (cheader_filename = "dova-model.h")]
public delegate R MapFunc<T,R> (T element);
