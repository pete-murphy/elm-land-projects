import { bypass, http, HttpResponse, passthrough } from "msw";

const DOG_API_URL = `https://dog.ceo/api/breeds/image/random`;

type PostId = `post-${string}`;
type AuthorId = `author-${string}`;
type ImageId = `image-${string}`;

type Post = {
  id: PostId;
  title: string;
  authorId: AuthorId;
  content: string;
  createdAt: string;
  imageIds: ReadonlyArray<ImageId>;
};

type Author = {
  id: AuthorId;
  name: string;
  bio: string;
};

type Image = {
  id: ImageId;
  url: string;
  alt?: string;
};

const authorArray: Array<Author> = [
  { id: "author-1", name: "Alice", bio: "I'm a writer and a poet" },
  { id: "author-2", name: "Bob", bio: "I'm a programmer and a gamer" },
  { id: "author-3", name: "Charlie", bio: "I'm a musician and a painter" },
  { id: "author-4", name: "David", bio: "I'm a teacher and a student" },
  { id: "author-5", name: "Eve", bio: "I'm a designer and a photographer" },
  { id: "author-6", name: "Frank", bio: "I'm a chef and a food critic" },
  { id: "author-7", name: "Grace", bio: "I'm a dancer and a choreographer" },
  { id: "author-8", name: "Heidi", bio: "I'm a gardener and a florist" },
  { id: "author-9", name: "Ivan", bio: "I'm a scientist and an engineer" },
  { id: "author-10", name: "Judy", bio: "I'm a doctor and a nurse" },
  { id: "author-11", name: "Kevin", bio: "I'm a lawyer and a judge" },
  { id: "author-12", name: "Linda", bio: "I'm a banker and an economist" },
];
const genAuthor = (): Author => authorArray[Math.floor(Math.random() * 12)]!;

let authors = new Map<AuthorId, Author>();
let postsByAuthor = new Map<AuthorId, Array<PostId>>();
function insertPostByAuthor(authorId: AuthorId, postId: PostId) {
  const posts = postsByAuthor.get(authorId) ?? [];
  posts.push(postId);
  postsByAuthor.set(authorId, posts);
}
let posts = new Map<PostId, Post>();
let images = new Map<ImageId, Image>();

function delayMsg(prefix: string, delay: number) {
  return [
    `%c[${prefix}] %cDelaying`,
    "color: cornflowerblue",
    "color: gray",
    `${(delay / 1000).toLocaleString(undefined, {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    })}s`,
  ];
}

export const handlers = [
  http.get(DOG_API_URL, passthrough),

  http.get("/api/posts", async (_) => {
    const AVG = 1_000 + 100 * posts.size;
    const delay = randomAround(AVG, 200);
    console.log(...delayMsg(_.requestId, delay));
    await sleep(delay);
    return HttpResponse.json(Array.from(posts.values()));
  }),

  http.get<{ id: PostId }>(
    "/api/posts/:id",
    async ({ request, params, ..._ }) => {
      const AVG = 200 + 50 * posts.size;
      const delay = randomAround(AVG, 200);
      console.log(...delayMsg(_.requestId, delay));
      await sleep(delay);
      const id = params.id;
      const post = posts.get(id);
      return HttpResponse.json(post);
    }
  ),

  http.get("/api/authors", async (_) => {
    const AVG = 500;
    const delay = randomAround(AVG, 100);
    console.log(...delayMsg(_.requestId, delay));
    await sleep(delay);
    return HttpResponse.json(
      Array.from(authors.values()).map((author) => ({
        ...author,
        postIds: postsByAuthor.get(author.id),
      }))
    );
  }),

  http.post<
    {},
    {
      title: string;
      authorId: AuthorId;
      content: string;
    }
  >("/api/posts", async ({ request, ..._ }) => {
    const delay = randomAround(200, 100);
    console.log(...delayMsg(_.requestId, delay));
    await sleep(delay);

    const { title, authorId, content } = await request.json();
    const author = authors.get(authorId);
    if (!author) {
      return HttpResponse.json({ error: "Author not found" }, { status: 404 });
    }
    const postId: PostId = `post-${crypto.randomUUID()}`;
    const post = {
      id: postId,
      title,
      authorId,
      content,
      createdAt: new Date().toISOString(),
      imageIds: [],
    };
    authors.set(author.id, author);
    posts.set(postId, post);
    insertPostByAuthor(author.id, postId);

    return HttpResponse.json(post, {
      headers: {
        Location: `/posts/${postId}`,
      },
    });
  }),
];

// Run

export async function run() {
  const MAX_POSTS = 100;
  while (posts.size < MAX_POSTS) {
    const delay = Math.random() * 10_000;
    console.log(...delayMsg("RUN", delay));
    await sleep(delay);

    const n = posts.size + 1;
    const imageIds = Array.from(
      { length: Math.floor(Math.random() * 5) },
      (): ImageId => `image-${crypto.randomUUID()}`
    );
    const author = genAuthor();
    const postId: PostId = `post-${crypto.randomUUID()}`;

    for (const imageId of imageIds) {
      const url = await fetch(DOG_API_URL)
        .then((response) => response.json())
        .then((data) => data.message);

      images.set(imageId, { id: imageId, url });
    }

    const post = {
      id: postId,
      title: `Post #${n}`,
      authorId: author.id,
      content: `This is post number ${n} in total, ${
        postsByAuthor.get(author.id)?.length
      } by this author (${author.name})`,
      createdAt: new Date().toISOString(),
      imageIds,
    };
    authors.set(author.id, author);
    posts.set(postId, post);
    insertPostByAuthor(author.id, postId);

    console.group(`%cCreated post #${n} by ${author.name}`, "color: gray");
    console.log(JSON.stringify(post, null, 2));
    console.groupEnd();
  }
}

// Utils

function randomAround(n: number, range: number) {
  return n + (Math.random() - 0.5) * range;
}
function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
