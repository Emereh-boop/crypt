import { redirect } from "@sveltejs/kit";

export const actions = {
  default: async ({ cookies, request }) => {
    const req = await request.formData();
    const response = await fetch("http://192.168.0.1/cgi-bin/api.cgi", {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        cmd: "login",
        password: req.get("password"),
        username: "root",
      }),
    });
    const res = await response.json();
    if (response.ok) {
      cookies.set("sessionId", res.data.values.session_id, {
        path: "/",
        maxAge: 60 * 15,
      });
      redirect(302, "/");
    } else {
      return {
        status: 302,
        headers: {
          location: "/auth?error=1",
        },
      };
    }
  },
};
