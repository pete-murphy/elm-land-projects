import { http, HttpResponse, passthrough } from "msw";
import { faker } from "@faker-js/faker";
import slugify from "slugify";

const SEED = 1;
faker.seed(SEED);

type PostId = `post-${string}`;
type AuthorId = `author-${string}`;
type ImageId = `image-${string}`;

type Post = {
  id: PostId;
  title: string;
  authorId: AuthorId;
  authorName: string;
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

const MAX_AUTHORS = faker.number.int({ min: 5, max: 10 });
const authorArray = Array.from(
  { length: MAX_AUTHORS },
  (_, i): Author => ({
    id: `author-${i}`,
    name: faker.person.fullName(),
    bio: faker.person.bio(),
  })
);

const genAuthor = (): Author =>
  authorArray[faker.number.int({ min: 0, max: authorArray.length - 1 })]!;

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

// Handlers

const endpoints = {
  posts: {
    getAll: "/api/posts",
    getById: "/api/posts/:id",
    create: "/api/posts",
  },
  authors: {
    getAll: "/api/authors",
    getById: "/api/authors/:id",
  },
  images: {
    getById: "/api/images/:id",
  },
};

const DOG_API_URL = `https://dog.ceo/api/breeds/image/random`;
const DOG_IMAGE_URL = `https://images.dog.ceo/breeds/:breed/:image`;

export const handlers = [
  http.get(DOG_API_URL, passthrough),
  http.get(DOG_IMAGE_URL, passthrough),

  http.get(endpoints.posts.getAll, async (_) => {
    const AVG = 1_000 + 50 * posts.size;
    const delay = randomAround(AVG, 200);
    console.log(...delayMsg(endpoints.posts.getAll, delay));
    await sleep(delay);
    return HttpResponse.json(
      Array.from(posts.values()).sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
    );
  }),

  http.get<{ id: PostId }>(
    endpoints.posts.getById,
    async ({ request, params }) => {
      const AVG = 2_000 + 50 * posts.size;
      const delay = randomAround(AVG, 200);
      console.log(...delayMsg(endpoints.posts.getById, delay));
      await sleep(delay);
      const id = params.id;
      const post = posts.get(id);
      if (!post) {
        return HttpResponse.json({ error: "Post not found" }, { status: 404 });
      }
      return HttpResponse.json(post);
    }
  ),

  http.get(endpoints.authors.getAll, async (_) => {
    const AVG = 500;
    const delay = randomAround(AVG, 100);
    console.log(...delayMsg(endpoints.authors.getAll, delay));
    await sleep(delay);
    return HttpResponse.json(
      Array.from(authors.values()).map((author) => ({
        ...author,
        postIds: postsByAuthor.get(author.id),
      }))
    );
  }),

  http.get<{ id: AuthorId }>(endpoints.authors.getById, async ({ params }) => {
    const AVG = 200;
    const delay = randomAround(AVG, 50);
    console.log(...delayMsg(endpoints.authors.getById, delay));
    await sleep(delay);
    const id = params.id;
    const author = authors.get(id);
    if (!author) {
      return HttpResponse.json({ error: "Author not found" }, { status: 404 });
    }
    return HttpResponse.json({
      ...author,
      posts: postsByAuthor.get(id)?.map((postId) => posts.get(postId)) ?? [],
    });
  }),

  http.post<
    {},
    {
      title: string;
      authorId: AuthorId;
      content: string;
    }
  >(endpoints.posts.create, async ({ request }) => {
    const delay = randomAround(200, 100);
    console.log(...delayMsg(endpoints.posts.create, delay));
    await sleep(delay);

    const { title, authorId, content } = await request.json();
    const author = authors.get(authorId);
    if (!author) {
      return HttpResponse.json({ error: "Author not found" }, { status: 404 });
    }
    const postId: PostId = `post-${slugify(title)}`;
    const post = {
      id: postId,
      title,
      authorId,
      authorName: author.name,
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

  http.get<{ id: ImageId }>(
    endpoints.images.getById,
    async ({ request, params }) => {
      const AVG = 200 + 50 * posts.size;
      const delay = randomAround(AVG, 200);
      console.log(...delayMsg(endpoints.images.getById, delay));
      await sleep(delay);
      const id = params.id;
      const image = images.get(id);
      if (!image) {
        return HttpResponse.json({ error: "Image not found" }, { status: 404 });
      }
      return HttpResponse.json(image);
    }
  ),
];

// Run

export async function createPosts() {
  const MAX_POSTS = 24;
  const INITIAL_POSTS = 16;
  while (posts.size < MAX_POSTS) {
    const delay = randomAround(1_000 + posts.size ** 1.2 * 100, 500);
    if (posts.size >= INITIAL_POSTS) {
      console.log(...delayMsg("createPosts", delay));
      await sleep(delay);
    }

    const n = posts.size + 1;
    const title = faker.lorem.sentence();
    const imageIds = Array.from(
      { length: faker.number.int({ min: 1, max: 3 }) },
      (): ImageId => `image-${faker.string.uuid()}`
    );
    const author = genAuthor();
    const postId: PostId = `post-${slugify(title)}`;

    for (const imageId of imageIds) {
      const url = await fetch(DOG_API_URL)
        .then((response) => response.json())
        .then((data) => data.message);

      images.set(imageId, { id: imageId, url });
    }

    const post = {
      id: postId,
      title,
      authorId: author.id,
      authorName: author.name,
      content: faker.lorem.paragraphs(3),
      createdAt:
        posts.size < INITIAL_POSTS
          ? faker.date.past().toISOString()
          : new Date().toISOString(),
      imageIds,
    };
    authors.set(author.id, author);
    posts.set(postId, post);
    insertPostByAuthor(author.id, postId);

    console.group(`%cCreated post ${n} by ${author.name}`, "color: gray");
    console.log(JSON.stringify(post, null, 2));
    console.groupEnd();
  }
}

// Utils

function randomAround(n: number, range: number) {
  return n + faker.number.float({ min: -0.5, max: 0.5 }) * range;
}
function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
