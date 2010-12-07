namespace Dova {
	public class ArrayList<T> : Dova.ListModel<T> {
		Javascript.Array<T> array = new Javascript.Array<T> ();

		class Iterator<T> : Dova.Iterator<T> {
			private ArrayList<T> list;
			private int index = -1;

			public Iterator (ArrayList<T> list) {
				this.list = list;
			}

			public override bool next () {
				if (index < list.length) {
					index++;
				}

				return (index < list.length);
			}

			public override T get () {
				return list[index];
			}
		}

		public ArrayList (Dova.List<T>? list = null) {
			if (list != null) {
				for (var i=0; i < list.length; i++) {
					append (list[i]);
				}
			}
		}
		public override void append (T element) {
			array.push (element);
		}
		public override void clear () {
			array = new Javascript.Array<T> ();
		}
		public override bool contains (T element) {
			return element in array;
		}
		public override T get (int index) {
			return array[index];
		}
		public override Dova.Iterator<T> iterator () {
			return new Iterator<T> (this);
		}
		public extern override bool remove (T element);
		public override void set (int index, T element) {
			array[index] = element;
		}
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
		public extern Dova.Iterable<K> keys { get; private set; }
		public extern int size { get; private set; }
		public extern Dova.Iterable<V> values { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public class HashSet<T> : Dova.SetModel<T> {
		public HashSet ();
		public extern override bool add (T element);
		public extern override void clear ();
		public extern override bool contains (T element);
		public extern override Dova.Iterator<T> iterator ();
		public extern override bool remove (T element);
		public extern override int size { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class Iterable<T> : Dova.Object {
		public Iterable ();
		public extern bool all (FilterFunc<T> func);
		public extern bool any (FilterFunc<T> func);
		public extern Dova.Iterable<T> drop (int n);
		public extern Dova.Iterable<T> filter (FilterFunc<T> func);
		public abstract Dova.Iterator<T> iterator ();
		public extern Dova.Iterable<R> map<R> (MapFunc<T,R> func);
		public extern Dova.Iterable<T> take (int n);
		public extern Dova.List<T> to_list ();
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
		public abstract int length { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class MapModel<K,V> : Dova.Object {
		public MapModel ();
		public abstract V get (K key);
		public abstract void set (K key, V value);
	}
	[CCode (cheader_filename = "dova-model.h")]
	public class PriorityQueue<T> : Dova.QueueModel<T> {
		public PriorityQueue (Dova.CompareFunc<T> comparer);
		public extern override T pop ();
		public extern override void push (T element);
		public extern int length { get; private set; }
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class QueueModel<T> : Dova.Object {
		public QueueModel ();
		public abstract T pop ();
		public abstract void push (T element);
	}
	[CCode (cheader_filename = "dova-model.h")]
	public abstract class SetModel<T> : Dova.Iterable<T> {
		protected SetModel ();
		public abstract bool add (T element);
		public abstract void clear ();
		public abstract bool contains (T element);
		public abstract bool remove (T element);
		public abstract int size { get; private set; }
	}
	public delegate int CompareFunc<T> (T a, T b);
}
public delegate bool FilterFunc<T> (T element);
public delegate R MapFunc<T,R> (T element);
